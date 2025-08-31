  use ../lib.nu [edit_repo maven_name_to_url]

def main [
  loader_version: string
] {
  let base_url = "https://meta.fabricmc.net/v2"
  let versions = http get ($base_url)/versions
  let oldest_minecraft_version = $versions.game | last | get version

  let loader_large_meta =  http get ($base_url)/versions/loader/($oldest_minecraft_version)/($loader_version)

  let loader_url = maven_name_to_url https://maven.fabricmc.net $loader_large_meta.loader.maven

  let update_lib_format = {|lib| {
    url: (maven_name_to_url $lib.url $lib.name)
    sha256: ($lib.sha256 | decode hex | encode base64)
  }}

  let launch_meta = $loader_large_meta.launcherMeta

  let to_add = {
    main: {
      url: $loader_url
      sha256: (http get $loader_url | hash sha256 --binary | encode base64)
    }
    libraries: ($launch_meta.libraries | update cells {$in | each $update_lib_format})
    mainClass: $launch_meta.mainClass
  }

  edit_repo {|data| $data | upsert ([fabric loaders $loader_version] | into cell-path) $to_add} 
  $to_add
}
