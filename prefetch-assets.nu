# Prefetches the Minecraft assets to the Nix store, because it's soooo long during build
def main [
  minecraft_version: string # The Minecraft version for which you want to prefetch the assets
] {
  http get https://launchermeta.mojang.com/mc/game/version_manifest.json | get versions | where id == $minecraft_version | first | http get $in.url | http get $in.assetIndex.url | get objects | values | par-each { |asset| nix-prefetch-url https://resources.download.minecraft.net/($asset.hash | str substring 0..1)/($asset.hash) $asset.hash --type sha1 }
  print -e "It worked! (I think)"
}
