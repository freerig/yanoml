inputs:
{ parsedMeta, versionInfos, files }:

let
  inherit (inputs) pkgs lib;
  myLib = import ../lib.nix inputs;

in {
  client = let
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

    wrapperInputs = {
      inherit (parsedMeta.client) libraries arguments mainClass;
      version = { inherit (versionInfos) id type; };
      ldLibPath = lib.makeLibraryPath runtimeLibs;

      assets = {
        root = let assets = parsedMeta.client.assets;
        in myLib.joinIntoDirectoryAttr "minecraft-assets-${assets.id}" {
          "objects" =
            myLib.joinIntoDirectoryAttr "minecraft-asset-objects-${assets.id}"
            assets.files;
          "indexes/${assets.id}.json" =
            pkgs.writeText "minecraft-assets-index-${assets.id}.json"
            (builtins.toJSON assets.index);
        };
        inherit (parsedMeta.client.assets) id;
      };

      nativesDir = pkgs.symlinkJoin {
        name = "natives";
        paths = builtins.concatMap
          (lib: if lib ? "natives" then [ lib.natives ] else [ ])
          parsedMeta.client.libraries;
      };

      programs = {
        java = lib.getExe pkgs.openjdk;
        uuidgen = "${pkgs.util-linux}/bin/uuidgen";
      };

      files = files.client or { };
    };

    dir = myLib.nu.writeNushellScriptDir "minecraft" {
      rootDir = ./nu;
      inputs = wrapperInputs;
    };
  in myLib.nu.wrapNushellFileBin "minecraft-client" "${dir}/client.nu";

  server = let
    wrapperInputs = {
      inherit (parsedMeta.server) libraries arguments mainClass;
      programs.java = lib.getExe pkgs.openjdk;
      files = files.server or { };
    };

    dir = myLib.nu.writeNushellScriptDir "minecraft" {
      rootDir = ./nu;
      inputs = wrapperInputs;
    };
  in myLib.nu.wrapNushellFileBin "minecraft-server" "${dir}/server.nu";
}

