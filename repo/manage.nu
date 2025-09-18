# Manage a YANOML repo
def main [] {
  help main
}

# Edit repo.json, creating it if it doesn't already exist
def edit_repo [
  apply: closure # This closure defines the way repo.json will be edited
  file: path = ./repo.json # The path to the json file
] {
  # If it doesn't exist, create it
  if not ($file | path exists) {
    echo "{}" | save $file
  }

  let data = open $file # Get the already existing file data...
  do $apply $data # ...and apply the closure to it 
    | to json
    | save -f $file
}

export def maven_name_to_url [
  maven_base_url: string
  name: string
] {
  let splited = $name | split row ":"
  let orgs = $splited.0 | split row "."
  let artifact_name = $splited.1
  let artifact_version = $splited.2

  [ $maven_base_url ...$orgs $artifact_name $artifact_version $"($artifact_name)-($artifact_version).jar" ] | str join "/"
}

# You better not use this one
def "main mod add manual" [
  format: string
  mod_name: string
  mod_version: string
] {
  let meta = $in

  def add [] {
    let repo_data = $in

    edit_repo { |repo|
      $repo | upsert ([mods $mod_name $mod_version] | into cell-path) $repo_data
    }
  }

  match $format {
    "modrinth" => {
      {
        type: raw
        version_type: $meta.version_type
        compatibility: {
          minecraft_versions: $meta.game_versions
          loaders: $meta.loaders
        }
        content: {
          jars: ($meta.files | where primary == true | each { |file| {
            name: $file.filename
            url: $file.url
            hash: $"sha512-($file.hashes.sha512 | decode hex | encode base64)" # We use SRI because some mod providers don't provide the hash we want. Maybe we should fetch the jar and compute the hash in the script direcly.
          }})
        }
      } | add
    }
    _ => {
      error make {
        msg: $"Mod format '($format)' is not supported yet'"
      }
    }
  }
}

# Add a Modrinth mod to the repo
def "main mod add modrinth" [
  project_id: string # The Modrinth project id that can be found by clicking the three points button at the top left of the mod page and then selecting "Copy ID" (or similar)
  --mod-name: string # The mod name, can overwrite the mod name provided by modrinth (use the name in the url)
  --mod-version: string # The mod version you want to install (not the Minecraft version)
  --minecraft-version (-v): string # The Minecraft version constraint
  --loader (-l): string # The loader you want (fabric, forge, quilt...)
  --version-type (-t): string = "release" # Change that to alpha or else if you need
  --select-latest (-L) # Select latest version if multiple are found
] {
  mut versions = http get https://api.modrinth.com/v2/project/($project_id)/version

  if $mod_version != null {
    $versions = $versions | where version_number == $mod_version
  }
  if $minecraft_version != null {
    $versions = $versions | where { |version| $minecraft_version in $version.game_versions }
  }
  if $version_type != null {
    $versions = $versions | where version_type == $version_type 
  }
  if $loader != null {
    $versions = $versions | where { |version| $loader in $version.loaders }
  }

  let mod_name = match $mod_name {
    null => {
      let project = http get https://api.modrinth.com/v2/project/($project_id)
      $project.slug
    }
    _ => $mod_name
  }

  match $versions {
    [] => { error make --unspanned { msg: "No version found" } }
    [$version] => {
      $version | main mod add manual modrinth $mod_name $version.version_number
    }
    _ => {
      if $select_latest {
        # FIXME: What if the latest version isn't the first version of the list?
        let version = $versions | first
        $version | main mod add manual modrinth $mod_name $version.version_number
        echo $version
      } else {
        print -e $versions
        error make --unspanned {msg: "Too many versions found! (use -L to select the latest)"}
      }
    }
  }
}

# Add a Minecraft vanilla version to the repo
def "main vanilla add" [
  minecraft_version: string # The Minecraft version you want to add (ex: 1.21.1)
] {
  # I really wanna make a cult arround how easy it is to implement the vanilla meta. If everything was this simple, we wouldn't even need a repo!

  let versions_manifest = http get https://piston-meta.mojang.com/mc/game/version_manifest.json
  let manifest_url = $versions_manifest.versions | where id == $minecraft_version | first | get url
  let manifest_hash = http get $manifest_url --raw | hash sha256 --binary | encode base64

  let to_add = {
    url: $manifest_url
    sha256: $manifest_hash
  }

  edit_repo { |data| $data | upsert ([vanilla $minecraft_version] | into cell-path) $to_add }
  $to_add
}

# Add a Fabric loader version to the repo
def "main fabric add loader" [
  --loader-version: string # The Fabric loader version (ex: 0.17.2). Defaults to the latest stable.
] {
  let base_url = "https://meta.fabricmc.net/v2"
  let versions = http get ($base_url)/versions

  let loader_version = $loader_version | default ($versions.loader | where stable | first | get version)

  let oldest_minecraft_version = $versions.game | last | get version
  let loader_large_meta =  http get ($base_url)/versions/loader/($oldest_minecraft_version)/($loader_version)

  let loader_url = maven_name_to_url https://maven.fabricmc.net $loader_large_meta.loader.maven

  let update_library_format = {|lib| {
    url: (maven_name_to_url $lib.url $lib.name)
    sha256: ($lib.sha256 | decode hex | encode base64)
  }}

  let launch_meta = $loader_large_meta.launcherMeta

  let to_add = {
    main: {
      url: $loader_url
      sha256: (http get $loader_url | hash sha256 --binary | encode base64)
    }
    libraries: ($launch_meta.libraries | update cells {$in | each $update_library_format})
    mainClass: $launch_meta.mainClass
  }

  edit_repo {|data| $data | upsert ([fabric loaders $loader_version] | into cell-path) $to_add} 
  $to_add
}

# Add a Fabric adapter to the repo
def "main fabric add minecraft" [
  minecraft_version: string # The Minecraft version for which you wanna add the fabric adapter (ex: 1.21.1)
] {
  let vanilla_output = main vanilla add $minecraft_version

  let base_url = "https://meta.fabricmc.net/v2"
  let versions = http get ($base_url)/versions
  let oldest_minecraft_version = $versions.game | last | get version

  let loader_large_meta =  http get ($base_url)/versions/loader/($minecraft_version) | first

  let intermediary_url = maven_name_to_url https://maven.fabricmc.net $loader_large_meta.intermediary.maven

  let to_add = {
    intermediary: {
      url: $intermediary_url
      sha256: (http get $intermediary_url | hash sha256 --binary | encode base64)
    }
  }

  edit_repo {|data| $data | upsert ([fabric adapters $minecraft_version] | into cell-path) $to_add}
  {
    vanilla: $vanilla_output
    fabric: $to_add
  }
}
