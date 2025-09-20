const inputs_file = path self ./inputs.json

# Start Minecraft
export def main [
  --player-name: string = "NixUser" # The Minecraft username
  --player-uuid: string # The Minecraft player UUID. It is used to uniquely identify players (to save inventory...).

  --game-dir: string = "~/.minecraft" # The Minecraft storage directory. It's used to save worlds, config...
] {
  let inputs = open $inputs_file

  let tmp = mktemp -d

  let native_files = glob ($inputs.nativesDir)/*
  if ($native_files | length) > 0 {
    cp -r ($inputs.nativesDir)/* $tmp
  }

  let replacements = {
    classpath: ($inputs.libraries | each {|lib| $lib | get jar --optional} | str join ":")
    classpath_separator: ":"
    natives_directory: $tmp
    assets_root: $inputs.assets.root
    assets_index_name: $inputs.assets.id

    auth_player_name: $player_name
    auth_uuid: ($player_uuid | default (^$inputs.programs.uuidgen))
    auth_access_token: "" # Not implemented
    clientid: "" # Not implemented
    user_type: mojang

    game_directory: ($game_dir | path expand)

    version_name: $inputs.version.id
    version_type: $inputs.version.type

    launcher_name: yanoml
    launcher_version: "42"
  }

  let replace = {|arg| $replacements | transpose name value | reduce --fold $arg {|it, acc| $acc | str replace $"${($it.name)}" $it.value}}

  let arguments = $inputs.arguments | items {|argType, args| [$argType ($args.raw | do $replace $in)]} | into record

  $env.LD_LIBRARY_PATH = $inputs.ldLibPath

  cd (mktemp -d)

  ^$inputs.programs.java ...$arguments.jvm $inputs.mainClass ...$arguments.game 
}
