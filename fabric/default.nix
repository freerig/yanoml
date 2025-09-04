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
          # FIXME: I'm not sure about the separator
            [
              "-Dfabric.addMods=${
                builtins.concatStringsSep ":" (builtins.concatMap
                  (mod: if mod ? "files" then mod.files.jars else [ mod ]) mods)
              }"
            ]);
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
          # FIXME: I'm not sure about the separator
            [
              "-Dfabric.addMods=${
                builtins.concatStringsSep ":" (builtins.concatMap
                  (mod: if mod ? "files" then mod.files.jars else [ mod ]) mods)
              }"
            ]);
      };
    };
    libraries = libraries.server;
    mainClass = fabricMeta.loader.mainClass.server;
  };
}

