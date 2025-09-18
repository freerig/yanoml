inputs: repoFile:

let
  inherit (inputs) pkgs;
  myLib = import ../lib.nix inputs;
  rawRepo = myLib.getJSON repoFile;
in {
  vanilla = builtins.mapAttrs (version: myLib.fetchJSON) rawRepo.vanilla;

  fabric = {
    loaders = builtins.mapAttrs (loaderVersion: loaderData: {
      inherit (loaderData) mainClass;
      main = pkgs.fetchurl loaderData.main;
      libraries =
        builtins.mapAttrs (libType: map pkgs.fetchurl) loaderData.libraries;
    }) rawRepo.fabric.loaders;
    adapters =
      builtins.mapAttrs (mcVersion: builtins.mapAttrs (idk: pkgs.fetchurl))
      rawRepo.fabric.adapters;
  };

  mods = builtins.mapAttrs (modName:
    builtins.mapAttrs (modVersionId: modVersionData:
      (if modVersionData.type == "raw" then {
        content = builtins.mapAttrs
          (fileType: map (data: pkgs.fetchurl { inherit (data) url hash; }))
          modVersionData.content or modVersionData.files or { }; # TODO: remove legacy support
      } else if modVersionData.type == "modrinth" then
      # modrinthToParsedMeta (myLib.fetchJSON {
      #   url = "https://api.modrinth.com/v2/version/${modVersionData.id}";
      #   inherit (modVersionData) sha256;
      # })
        throw
        "modrinth is not implemented (see https://github.com/modrinth/code/issues/4297)"
      else
        throw "${modVersionData.type} mod type doesn't exist"))) rawRepo.mods;
}
