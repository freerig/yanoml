inputs:
{ minecraftParsedMeta, fabricMeta, mods ? [ ] }:

let
  libraries = let
    mkLibs = role:
      minecraftParsedMeta.${role}.libraries ++ (map (lib: { jar = lib; })
        (fabricMeta.loader.libraries.common
          ++ fabricMeta.loader.libraries.${role}
          ++ [ fabricMeta.loader.main fabricMeta.adapter.intermediary ]));
  in {
    client = mkLibs "client";
    server = mkLibs "server";
  };

  # FIXME: I'm not sure about the separator, maybe it's not cross-compatible
  joinedMods = builtins.concatStringsSep ":" (builtins.concatMap
    (mod: if mod ? "content" then mod.content.jars else [ mod ]) mods);

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
            [ "-Dfabric.addMods=${joinedMods}" ]);
      };
    };
    libraries = libraries.client;
    mainClass = fabricMeta.loader.mainClass.client;
  };
  server = {
    arguments = {
      inherit (minecraftParsedMeta.server.arguments) game;
      jvm = {
        raw = minecraftParsedMeta.server.arguments.jvm.raw
          ++ (if builtins.length mods == 0 then
            [ ]
          else
            [ "-Dfabric.addMods=${joinedMods}" ]);
      };
    };
    libraries = libraries.server;
    mainClass = fabricMeta.loader.mainClass.server;
  };
}

