use ../repo/manage.nu *

const dir = path self .
const repo = path self ..

def --wrapped repo [...args] {
  nix run $"($repo)#repo" -- ...$args
} 

cd $dir
rm -f repo.json

### You can replace every `repo` with `nix run github:freerig/yanoml#repo --`

# Vanilla
repo vanilla add "1.21.1"

# Fabric
repo fabric add loader --loader-version "0.17.2"
repo fabric add minecraft "1.21.1"

# Quilt
repo quilt add loader --loader-version "0.29.1"
repo quilt add minecraft "1.21.1"

# Mods
# (We have to do static versions, as the `default.nix` file hardcodes them)
def add-mod [
  id: string
  version: string
] {
  repo mod add modrinth $id --mod-version $version
}

add-mod P7dR8mSH "0.116.6+1.21.1" # Add Fabric API
add-mod nvQzSEkH "15.10.2+fabric" # Add Jade
add-mod AANobbMI "mc1.21.1-0.6.0-fabric" # Add Sodium (this version is compatible with Immerive Portals)
add-mod zJpHMkdD "v6.0.6-mc1.21.1" # Add Immersive Portals
add-mod t5W7Jfwy "3.8.3+1.14.4-1.21" # Add Pehkui
add-mod mOgUt4GM "11.0.3" # Add Mod Menu
