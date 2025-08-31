use ../lib.nu [edit_repo maven_name_to_url]

# Add an adapter for Fabric (this mod loader need one for each Minecraft version)
def main [
  minecraft_version: string # The Minecraft version for which you wanna add the fabric adapter (ex: 1.21.1)
] {
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
  $to_add
}
