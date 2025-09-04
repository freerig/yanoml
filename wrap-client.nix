inputs:
{ parsedMeta, versionInfos }:

let
  inherit (inputs) pkgs lib;
  myLib = import ./lib.nix inputs;

  runtimeLibs = with pkgs;
    [
      libGL
      mesa
      glfw
      openal
      # (lib.getLib stdenv.cc.cc)
    ] ++ (if stdenv.hostPlatform.isLinux then [
      libpulseaudio
      udev
      flite
    ] else
      [ ]);

in (myLib.writeNushellScript "mc.nu" {
  inherit (parsedMeta) libraries arguments mainClass;
  version = { inherit (versionInfos) id type; };
  ldLibPath = lib.makeLibraryPath runtimeLibs;
} # nu
  ''
    let inputs = $env.INPUT | from json

    # Start Minecraft
    def main [
      --player-name: string = "NixUser" # The Minecraft username
      --player-uuid: string # The Minecraft player UUID. It is used to uniquely identify players (to save inventory...).

      --game-dir: string = "~/.minecraft" # The Minecraft storage directory. It's used to save worlds, config...
    ] {
      let tmp = mktemp -d

      cp -r ${
        pkgs.symlinkJoin {
          name = "natives";
          paths = builtins.concatMap
            (lib: if lib ? "natives" then [ lib.natives ] else [ ])
            parsedMeta.libraries;
        }
      } $tmp

      let replacements = {
        classpath: ($inputs.libraries | each {|lib| $lib.jar} | str join ":")
        classpath_separator: ":"
        natives_directory: $tmp
        assets_root: ${
          let assets = parsedMeta.assets;
          in myLib.joinIntoDirectoryAttr "minecraft-assets-${assets.id}" {
            "objects" =
              myLib.joinIntoDirectoryAttr "minecraft-asset-objects-${assets.id}"
              assets.files;
            "indexes/${assets.id}.json" =
              pkgs.writeText "minecraft-assets-index-${assets.id}.json"
              (builtins.toJSON assets.index);
          }
        }
        assets_index_name: "${parsedMeta.assets.id}"

        auth_player_name: $player_name
        auth_uuid: ($player_uuid | default (${pkgs.util-linux}/bin/uuidgen))
        auth_access_token: "" # Not implemented
        clientid: "" # Not implemented
        user_type: mojang

        game_directory: ($game_dir | path expand)

        version_name: $inputs.version.id
        version_type: $inputs.version.type

        launcher_name: yanoml
        launcher_version: "42"
      }

      let replace = {|arg| $replacements | transpose name value | reduce --fold $arg {|it, acc| $acc | str replace $"''${($it.name)}" $it.value}}

      let arguments = $inputs.arguments | items {|argType, args| [$argType ($args.raw | do $replace $in)]} | into record

      $env.LD_LIBRARY_PATH = $inputs.ldLibPath

      cd (mktemp -d)

      ${
        lib.getExe pkgs.openjdk
      } ...$arguments.jvm $inputs.mainClass ...$arguments.game 
    }
  '')
# see https://ryanccn.dev/posts/inside-a-minecraft-launcher/

