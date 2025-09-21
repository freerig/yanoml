inputs:
{ minecraftParsedMeta, fabricLikeMeta, loader, mods ? [ ] }:

let
  libraries = let
    mkLibs = role:
      minecraftParsedMeta.${role}.libraries ++ (map (lib: { jar = lib; })
        (fabricLikeMeta.loader.libraries.common
          ++ fabricLikeMeta.loader.libraries.${role}
          ++ (builtins.attrValues fabricLikeMeta.adapter)
          ++ [ fabricLikeMeta.loader.main ]));
  in {
    client = mkLibs "client";
    server = mkLibs "server";
  };

  jars = builtins.concatMap
    (mod: if mod ? "content" then mod.content.jars else [ mod ]) mods;
  joinedMods = builtins.concatStringsSep ":" jars;

  addModsArg = if loader == "fabric" then
    "fabric.addMods"
  else if loader == "quilt" then
    "loader.addMods"
  else
    throw "Fabric-like loader ${loader} isn't implemented";

  getBaseParsed = role: {
    arguments = {
      inherit (minecraftParsedMeta.${role}.arguments) game;
      jvm = {
        raw = minecraftParsedMeta.${role}.arguments.jvm.raw
          ++ (if builtins.length mods == 0 then
            [ ]
          else
            [ "-D${addModsArg}=${joinedMods}" ]);
      };
    };
    libraries = libraries.${role};
    mainClass = fabricLikeMeta.loader.mainClass.${role};
    includeStores = minecraftParsedMeta.${role}.includeStores or [ ] ++ jars;
  };

in {
  client = getBaseParsed "client" // {
    inherit (minecraftParsedMeta.client) assets;
  };
  server = getBaseParsed "server";
}

