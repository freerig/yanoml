use ./bubble.nu

const inputs_file = path self ./inputs.json

# Start Minecraft
export def main [
  --player-name: string = "NixUser" # The Minecraft username
  --player-uuid: string # The Minecraft player UUID. It is used to uniquely identify players (to save inventory...).

  --game-dir: string = "~/.minecraft" # The Minecraft storage directory. It's used to save worlds, config...

  --bubblewrap # Weather or not to use a Bubblewrap sandboxing layer (some features like sound assets or languages doesn't work)
] {
  let game_dir = $game_dir | path expand;
  mkdir $game_dir

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
    auth_uuid: ($player_uuid | default (random uuid))
    auth_access_token: "" # Not implemented
    clientid: "" # Not implemented
    user_type: mojang

    game_directory: (if $bubblewrap { "/minecraft" } else { $game_dir })

    version_name: $inputs.version.id
    version_type: $inputs.version.type

    launcher_name: yanoml
    launcher_version: "42"
  }

  let replace = {|arg| $replacements | transpose name value | reduce --fold $arg {|it, acc| $acc | str replace $"${($it.name)}" $it.value}}

  let arguments = $inputs.arguments | items {|argType, args| [$argType ($args.raw | do $replace $in)]} | into record

  if $bubblewrap {  
    bubble base
    | bubble add store ...[
      # $inputs.assets.root # This adds too many arguments, see https://github.com/containers/bubblewrap/issues/703
      $inputs.programs.java
      ...($inputs.libraries | each {|lib| $lib | get jar --optional})
      ...$inputs.includeStores
    ]
    | bubble add raw "--dev-bind" /dev /dev
    | bubble add raw "--share-net"
    | bubble set env DISPLAY :0
    | bubble set env XDG_RUNTIME_DIR $env.XDG_RUNTIME_DIR
    | bubble set env LD_LIBRARY_PATH $inputs.ldLibPath
    | bubble bind same /run /sys /etc /tmp/.X11-unix
    | bubble bind different --writable $game_dir /minecraft
    | do {
      let params = $in
      $inputs.files | transpose name path | reduce --fold $params { |file, acc|
        $acc | bubble bind different $file.path ("/minecraft" | path join $file.name | path expand)
      }
    } $in
    | bubble run --bubblewrap $inputs.programs.bubblewrap $inputs.programs.java ...$arguments.jvm $inputs.mainClass ...$arguments.game

  } else {
    cd $game_dir
    $inputs.files | items { |name, dir| ln -s --backup=numbered $dir $name }

    cd (mktemp -d)
    LD_LIBRARY_PATH=$inputs.ldLibPath ^$inputs.programs.java ...$arguments.jvm $inputs.mainClass ...$arguments.game

    cd $game_dir
    $inputs.files | items { |name, dir| rm $name } | ignore
  }

}
