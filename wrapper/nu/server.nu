use ./bubble.nu

const inputs_file = path self ./inputs.json

# Start a Minecraft server
def main [
  --server-dir: string = "./minecraft-server" # The Minecraft server storage directory. It's used to save worlds, config...

  --bubblewrap # Weather or not to use a Bubblewrap sandboxing
] {
  let inputs = open $inputs_file

  let replacements = {
    classpath: ($inputs.libraries | each {|lib| $lib | get jar --optional} | str join ":")
    classpath_separator: ":"
  }

  let replace = {|arg| $replacements | transpose name value | reduce --fold $arg {|it, acc| $acc | str replace $"${($it.name)}" $it.value}}

  let arguments = $inputs.arguments | items {|argType, args| [$argType ($args.raw | do $replace $in)]} | into record

  let server_dir = ($server_dir | path expand)
  mkdir $server_dir

  cd $server_dir

  if $bubblewrap {
    bubble base
    | bubble add store ...[
      $inputs.programs.java
      ...($inputs.libraries | each {|lib| $lib | get jar --optional})
      ...$inputs.includeStores
    ]
    | bubble add raw "--share-net"
    | bubble set env LD_LIBRARY_PATH $inputs.ldLibPath
    | bubble bind different --writable $server_dir /minecraft
    | bubble add raw "--chdir" /minecraft
    | do {
      let params = $in
      $inputs.files | transpose name path | reduce --fold $params { |file, acc|
        $acc | bubble bind different $file.path ("/minecraft" | path join $file.name | path expand)
      }
    } $in
    | bubble run --bubblewrap $inputs.programs.bubblewrap $inputs.programs.java ...$arguments.jvm $inputs.mainClass ...$arguments.game

  } else {
    $inputs.files | items { |name, dir| ln -s --backup=numbered $dir $name }

    LD_LIBRARY_PATH=$inputs.ldLibPath ^$inputs.programs.java ...$arguments.jvm $inputs.mainClass ...$arguments.game

    $inputs.files | items { |name, dir| rm $name } | ignore
  }
}
