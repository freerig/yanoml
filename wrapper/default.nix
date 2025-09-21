inputs:
{ parsedMeta, versionInfos, files }:

let
  inherit (inputs) pkgs lib;
  myLib = import ../lib.nix inputs;

  programs = {
    java = lib.getExe pkgs.openjdk;
    bubblewrap = lib.getExe pkgs.bubblewrap;
  };

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

  getBaseInputs = role: {
    inherit (parsedMeta.${role}) libraries arguments mainClass;
    inherit programs;
    version = { inherit (versionInfos) id type; };
    files = files.${role} or { };

    ldLibPath = lib.makeLibraryPath runtimeLibs;
    includeStores = parsedMeta.${role}.includeStores or [ ] ++ runtimeLibs;
  };

in {
  client = let
    wrapperInputs = getBaseInputs "client" // {
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
    };

    dir = myLib.nu.writeNushellScriptDir "minecraft" {
      rootDir = ./nu;
      inputs = wrapperInputs;
    };
  in myLib.nu.wrapNushellFileBin "minecraft-client" "${dir}/client.nu";

  server = let
    dir = myLib.nu.writeNushellScriptDir "minecraft" {
      rootDir = ./nu;
      inputs = getBaseInputs "server";
    };
  in myLib.nu.wrapNushellFileBin "minecraft-server" "${dir}/server.nu";
}

