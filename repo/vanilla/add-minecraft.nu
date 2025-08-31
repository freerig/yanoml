use ../lib.nu [edit_repo]

# Add a Minecraft version to the repo
def main [
  minecraft_version: string # The Minecraft version you want to add (ex: 1.21.1)
] {
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
