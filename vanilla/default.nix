inputs:
{ minecraftRawMeta }:

let
  inherit (inputs) pkgs lib;
  myLib = import ../lib.nix inputs;

  fetchSha1 = meta: pkgs.fetchurl { inherit (meta) url sha1; };

  # FIXME: This should be more flexible
  currentOs = {
    name = "linux";
    arch = "x86_64";
    version = throw "Not implemented";
  };

  # This function computes all the rules and say if the args have to be applied
  evalRules = rules:
    let
      evalWeight = rule:
        let
          potentialWeight = if rule.action == "allow" then
            1
          else if rule.action == "disallow" then
            -1
          else
            throw
            "Unknown Minecraft manifest arguement rule action '${rule.action}'";
          applied = let
            osFlag = if rule ? "os" then
              let
                requiredOs = rule.os;
                keys = builtins.attrNames requiredOs;
                checkKey = key:
                  builtins.getAttr key requiredOs
                  == builtins.getAttr key currentOs;
                flags = map checkKey keys;
              in !builtins.elem false flags
            else
              true;
            featuresFlag = !rule ? "features";
          in osFlag && featuresFlag;
        in if applied then potentialWeight else 0;
      ruleWeights = map evalWeight rules;
    in if builtins.elem (-1) ruleWeights then
      false
    else
      builtins.elem 1 ruleWeights;

in {
  client = {
    mainClass = minecraftRawMeta.mainClass;

    libraries = map (rawLibrary:
      {
        jar = fetchSha1 rawLibrary.downloads.artifact;
      } // (if rawLibrary ? "natives" then {
        natives = pkgs.runCommand "minecraft-java-natives" { } ''
          mkdir -p $out
          cd $TMPDIR

          ${pkgs.jdk}/bin/jar xf ${
            fetchSha1 rawLibrary.downloads.classifiers.${
              rawLibrary.natives.${currentOs.name}
            }
          }

          shopt -s nullglob
          for f in ./*.{dylib,so,dll}; do
            mv "$f" "$out/"
          done
        '';
      } else
        { }))

      (builtins.filter (x: !x ? "rules" || evalRules x.rules)
        minecraftRawMeta.libraries) ++ [{
          jar = fetchSha1 minecraftRawMeta.downloads.client;
          natives = [ ];
        }];

    arguments = builtins.mapAttrs (argListType: manifestArgs: {
      raw = builtins.concatMap (arg:
        if builtins.isString arg then
          [ arg ]
        else if (evalRules arg.rules) then
          if builtins.isString arg.value then [ arg.value ] else arg.value
        else
          [ ]) manifestArgs;
    }) minecraftRawMeta.arguments;

    assets = let
      indexes = fetchSha1 minecraftRawMeta.assetIndex;
      objects = (myLib.getJSON indexes).objects;
      hashToPath = sha1: "${builtins.substring 0 2 sha1}/${sha1}";
      fetchAsset = sha1:
        fetchSha1 {
          url = "https://resources.download.minecraft.net/${hashToPath sha1}";
          inherit sha1;
        };
    in {
      id = minecraftRawMeta.assetIndex.id;
      index = myLib.getJSON indexes;
      files = builtins.listToAttrs (builtins.map (resource:
        let sha1 = resource.hash;
        in {
          name = hashToPath sha1;
          value = fetchAsset sha1;
        }) (builtins.attrValues objects));
    };
  };
  server = let
    extracted = pkgs.runCommand "minecraft-java-natives" { } ''
      mkdir -p $out
      cd $out
      ${pkgs.jdk}/bin/jar xf ${fetchSha1 minecraftRawMeta.downloads.server}
    '';
  in {
    arguments = {
      jvm.raw = [ "-cp" "\${classpath}" ];
      game.raw = [ ];
    };
    libraries = let
      rawPaths = lib.splitString ";"
        (builtins.readFile "${extracted}/META-INF/classpath-joined");
    in map (rawPath: { jar = "${extracted}/META-INF/${rawPath}"; }) rawPaths;
    mainClass = builtins.readFile "${extracted}/META-INF/main-class";
  };
}
