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

  # FIXME: I'm not sure about the separator, maybe it's not cross-compatible
  joinedMods = builtins.concatStringsSep ":" (builtins.concatMap
    (mod: if mod ? "content" then mod.content.jars else [ mod ]) mods);

  addModsArg = if loader == "fabric" then
    "fabric.addMods"
  else if loader == "quilt" then
    "loader.addMods"
  else
    throw "Fabric-like loader ${loader} isn't implemented";

in {
  client = {
    inherit (minecraftParsedMeta.client) assets;
    arguments = {
      inherit (minecraftParsedMeta.client.arguments) game;
      jvm = {
        raw = minecraftParsedMeta.client.arguments.jvm.raw
          ++ (if builtins.length mods == 0 then
            [ ]
          else
            [ "-D${addModsArg}=${joinedMods}" ]);
      };
    };
    libraries = libraries.client;
    mainClass = fabricLikeMeta.loader.mainClass.client;
  };
  server = {
    arguments = {
      inherit (minecraftParsedMeta.server.arguments) game;
      jvm = {
        raw = minecraftParsedMeta.server.arguments.jvm.raw
          ++ (if builtins.length mods == 0 then
            [ ]
          else
            [ "-D${addModsArg}=${joinedMods}" ]);
      };
    };
    libraries = libraries.server;
    mainClass = fabricLikeMeta.loader.mainClass.server;
  };
}

