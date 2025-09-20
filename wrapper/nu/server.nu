const inputs_file = path self ./inputs.json

# Start a Minecraft server
def main [
  --server-dir: string = "./minecraft-server" # The Minecraft server storage directory. It's used to save worlds, config...
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

  ^$inputs.programs.java ...$arguments.jvm $inputs.mainClass ...$arguments.game 
}
