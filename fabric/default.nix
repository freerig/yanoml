inputs:
{ minecraftParsedMeta, fabricMeta, mods ? [ ] }:

let
  libraries = {
    client = minecraftParsedMeta.client.libraries ++ (map (lib: { jar = lib; })
      (fabricMeta.loader.libraries.common ++ fabricMeta.loader.libraries.client
        ++ [ fabricMeta.loader.main fabricMeta.adapter.intermediary ]));
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
}

