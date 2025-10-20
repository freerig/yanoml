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
        myLib = import ./lib.nix inputs;
      in {
        mkMinecraft = { minecraftVersion, repoFile, modLoader ? "vanilla"
          , modLoaderVersion ? null, modPredicate ? (x: [ ]), files ? { } }:
          let
            repo = (import ./repo inputs repoFile);
            minecraftRawMeta = repo.vanilla.${minecraftVersion};
            minecraftParsedMeta =
              (import ./vanilla inputs { inherit minecraftRawMeta; });

            parsedMeta = if modLoader == "vanilla" then
              minecraftParsedMeta
            else if modLoader == "fabric" || modLoader == "quilt" then
              (import ./fabric-like inputs {
                inherit minecraftParsedMeta;
                fabricLikeMeta = let meta = repo.${modLoader};
                in {
                  loader = meta.loaders.${modLoaderVersion};
                  adapter = meta.adapters.${minecraftVersion};
                };
                loader = modLoader;
                mods = modPredicate repo.mods;
              })
            else
              throw
              "Mod loader ${modLoader} is not implemented yet (make an issue if you want)";

          in import ./wrapper inputs {
            inherit parsedMeta files;
            versionInfos = { inherit (minecraftRawMeta) id type; };
          };

        packages.examples = import ./examples inputs { inherit self system; };

        apps = let
          mkNuApp = name: file: {
            type = "app";
            program = builtins.toString
              (myLib.nu.writeSimpleNushellScript "manage-yanoml-repo"
                (builtins.readFile file));
          };
        in {
          prefetch = mkNuApp "prefetch-minecraft-assets" ./prefetch-assets.nu;
          repo = mkNuApp "manage-yanoml-repo" ./repo/manage.nu;
        };
      });
}
