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
        mkMinecraftClient = { minecraftVersion, repoFile, modLoader ? "vanilla"
          , modLoaderVersion ? null, modPredicate ? (x: [ ]) }:
          let
            repo = (import ./repo inputs repoFile);
            minecraftRawMeta = repo.vanilla.${minecraftVersion};
            minecraftParsedMeta =
              (import ./vanilla inputs { inherit minecraftRawMeta; });

            parsedMeta = if modLoader == "vanilla" then
              minecraftParsedMeta.client
            else if modLoader == "fabric" then
              (import ./fabric inputs {
                inherit minecraftParsedMeta;
                fabricMeta = {
                  loader = repo.fabric.loaders.${modLoaderVersion};
                  adapter = repo.fabric.adapters.${minecraftVersion};
                };
                mods = modPredicate repo.mods;
              }).client
            else
              throw
              "Mod loader ${modLoader} is not implemented yet (make an issue if you want)";
          in pkgs.writeShellScriptBin "mc" (import ./wrap-launcher.nix inputs {
            inherit parsedMeta;
            versionInfos = { inherit (minecraftRawMeta) id type; };
          });
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
