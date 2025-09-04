{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        lib = nixpkgs.lib;
        pkgs = import nixpkgs { inherit system; };
        inputs = { inherit lib pkgs; };
      in {
        mkMinecraft = let
          mkRole = role:
            { minecraftVersion, repoFile, modLoader ? "vanilla"
            , modLoaderVersion ? null, modPredicate ? (x: [ ]) }:
            let
              repo = (import ./repo inputs repoFile);
              minecraftRawMeta = repo.vanilla.${minecraftVersion};
              minecraftParsedMeta =
                (import ./vanilla inputs { inherit minecraftRawMeta; });

              parsedMeta = if modLoader == "vanilla" then
                minecraftParsedMeta.${role}
              else if modLoader == "fabric" then
                (import ./fabric inputs {
                  inherit minecraftParsedMeta;
                  fabricMeta = {
                    loader = repo.fabric.loaders.${modLoaderVersion};
                    adapter = repo.fabric.adapters.${minecraftVersion};
                  };
                  mods = modPredicate repo.mods;
                }).${role}
              else
                throw
                "Mod loader ${modLoader} is not implemented yet (make an issue if you want)";
            in pkgs.writeShellScriptBin "mc" ''
              ${
                if role == "client" then
                  import ./wrap-client.nix inputs {
                    inherit parsedMeta;
                    versionInfos = { inherit (minecraftRawMeta) id type; };
                  }
                else if role == "server" then
                  import ./wrap-server.nix inputs { inherit parsedMeta; }
                else
                  throw ''
                    Minecraft role ${role} doesn't exist (you must choose "client" or "server")''
              } "$@"'';
        in params: {
          client = mkRole "client" params;
          server = mkRole "server" params;
        };

        packages = {
          examples = import ./examples inputs { inherit self system; };
        };
        apps = let
          mkNuApp = name: file: {
            type = "app";
            program = builtins.toString (pkgs.writeShellScript name
              ''${lib.getExe pkgs.nushell} ${file} "$@"'');
          };
          repo = ./repo;
        in {
          prefetch = mkNuApp "prefetch-minecraft-assets" ./prefetch-assets.nu;
          repo = {
            vanilla.add-minecraft = mkNuApp "add-minecraft-vanilla"
              "${repo}/vanilla/add-minecraft.nu";
            fabric = {
              add-minecraft = mkNuApp "add-minecraft-fabric"
                "${repo}/fabric/add-minecraft.nu";
              add-loader =
                mkNuApp "add-minecraft-fabric" "${repo}/fabric/add-loader.nu";
            };
            mods = {
              add-mod =
                mkNuApp "add-minecraft-fabric" "${repo}/mods/add-mod.nu";
            };
          };
        };
      });
}
