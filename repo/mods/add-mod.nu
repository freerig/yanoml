use ../lib.nu edit_repo

def add-version [
  mod_name: string
  modrinth_data: record
] {
  let to_add = {
    type: raw # Modrinth is not supported yet
    version_type: $modrinth_data.version_type
    minecraft_versions: $modrinth_data.game_versions
    loaders: $modrinth_data.loaders
    files: {
      jars: ($modrinth_data.files | where primary == true | each { |file| {
        name: $file.filename
        url: $file.url
        hash: $"sha512-($file.hashes.sha512 | decode hex | encode base64)" # We use SRI because some mod providers don't provide the hash we want. Maybe we should fetch the jar and compute the hash in the script direcly.
      }})
    }
  }
  edit_repo {|data| $data | upsert ([mods $mod_name $modrinth_data.version_number] | into cell-path) $to_add}
}

# Add a mod to the repo
def main [
  project_id: string # The Modrinth mod id that can be found by clicking the three points button at the top left of the mod page and then selecting "Copy ID" (or similar)
  --mod-name: string # The mod name, can overwrite the mod name provided by modrinth (use the name in the url)
  --mod-version: string # The mod version you want to install (not the Minecraft version)
  --minecraft-version (-v): string # The Minecraft version constraint
  --version-type (-t): string = "release" # Change that to alpha or else if you need
  --select-latest (-L) # Select latest version if multiple are found
  --loader (-l): string # The loader you want (fabric, forge, quilt...)
] {
  mut versions = http get https://api.modrinth.com/v2/project/($project_id)/version

  let mod_name = match $mod_name {
    null => {
      let project = http get https://api.modrinth.com/v2/project/($project_id)
      $project.slug
    }
    _ => $mod_name
  }

  match $mod_version {
    null => {
      match $minecraft_version {
        null => null
        _ => { $versions = ($versions | where { |version| $minecraft_version in $version.game_versions }) }
      }

      match $loader {
        null => null
        _ => { $versions = ($versions | where { |version| $loader in $version.loaders }) }
      }

      $versions = ($versions | where version_type == $version_type)
    }
    _ => { $versions = ($versions | where version_number == $mod_version) }
  }

  match $versions {
    [] => { error make --unspanned { msg: "No version found" } }
    [$version] => {
      add-version $mod_name $version
    }
    _ => {
      if $select_latest {
        # FIXME: What if the latest version isn't the first version of the list?
        add-version $mod_name ($versions | first)
        echo ($versions | first)
      } else {
        print -e $versions
        error make --unspanned {msg: "Too many versions found!"}
      }
    }
  }
}

# # Adds an entry to mods.json, so it's usable from the mods.nix file.
# def main [
#   mod_name: string  # The mod name
#   --mod-version: string = default  # The mod version (not the Minecraft version) 
#   mod_loader: string  # The mod loader, can be forge or fabric
#   minecraft_version: string  # The minecraft version. Ex: 1.21.1
#   jar_url: string  # The http(s) download URL of the .jar file of the mod
#   --force (-f)  # Bypass the mod name checks (be carefull of misspelling!)
# ] {
#   let path = "mods.json"
#   if not ($path | path exists) {
#     echo "{}" | save $path
#   }
#   let mods = open $path

#   if not ($mod_loader in ["forge" "fabric"]) {
#     error make {msg: "Mod loader must be either forge or fabric"}
#   }

#   if not $force {
#     let mods_names_list = $mods | values | each {|x| $x | values } | flatten | each {|x| $x | columns } | flatten
#     if not ($mod_name in $mods_names_list) {
#       error make {msg: "Unknown mod : please use the --force flag"}
#     }
#   }

#   let jar_url = $jar_url | url decode

#   let jar_infos = {
#     url: $jar_url
#     hash: (nix hash convert --hash-algo sha256 (do {
#       let output = (nix-prefetch-url $jar_url | complete)
#       if $output.exit_code != 0 {
#         print $output
#         error make {msg: $"Can't prefetch URL"}
#       }
#       $output.stdout | str trim
#     }) err> /dev/null)
#   }

#   # TODO: Sort it all!
#   $mods
#     | upsert ([ $mod_loader $minecraft_version $mod_name $mod_version ] | into cell-path) $jar_infos
#     | to json 
#     | save -f $path
# }
