inputs: versionManifest:

let
  inherit (inputs) pkgs;
  myLib = import ./lib.nix inputs;

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

  rawArguments = builtins.mapAttrs (argListType: manifestArgs:
    builtins.concatMap (arg:
      if builtins.isString arg then
        [ arg ]
      else if (evalRules arg.rules) then
        if builtins.isString arg.value then [ arg.value ] else arg.value
      else
        [ ]) manifestArgs) versionManifest.arguments;

  librariesJars = let
    rawLibraries = builtins.filter (x: !x ? "rules" || evalRules x.rules)
      versionManifest.libraries;
  in map (library: fetchSha1 library.downloads.artifact) rawLibraries
  ++ [ (fetchSha1 versionManifest.downloads.client) ];

  assets = let
    indexes = fetchSha1 versionManifest.assetIndex;
    objects = (myLib.getJSON indexes).objects;
    hashToPath = sha1: "${builtins.substring 0 2 sha1}/${sha1}";
    fetchAsset = sha1:
      fetchSha1 {
        url = "https://resources.download.minecraft.net/${hashToPath sha1}";
        inherit sha1;
      };
  in {
    objectsByDir = builtins.listToAttrs (builtins.map (resource:
      let sha1 = resource.hash;
      in {
        name = hashToPath sha1;
        value = fetchAsset sha1;
      }) (builtins.attrValues objects));
    indexesFile = indexes;
    id = versionManifest.assetIndex.id;
  };

in {
  client = {
    inherit librariesJars rawArguments assets;
    inherit (versionManifest) mainClass;
  };
}

# FIXME: Older versions need it!
# natives_directory = builtins.toString
#   (pkgs.runCommand "minecraft-java-natives" { } ''
#     mkdir -p $out
#     cd $TMPDIR

#     ${builtins.concatStringsSep "\n" (map (library:
#       "${pkgs.jdk}/bin/jar xf ${
#         fetchSha1 library.downloads.classifiers.${
#           library.natives.${currentOs.name}
#         }
#       }") (builtins.filter (library: library ? "natives")
#         rawLibraries))}

#     shopt -s nullglob
#     for f in ./*.{dylib,so,dll}; do
#       mv "$f" "$out/"
#     done
#   '');

# arguments = let
#   processRawArgument = argument:
#     if builtins.isString argument then
#       [ argument ]
#     else if (evalRules argument.rules) then
#       if builtins.isString argument.value then
#         [ argument.value ]
#       else
#         argument.value
#     else
#       [ ];

#   giveVariables = args:
#     let
#       joinIntoDirectory = name: derivations:
#         pkgs.runCommand name { } ''
#           mkdir -p $out
#           ${builtins.concatStringsSep "\n"
#           (map (d: "ln -s ${d} $out/${d.name}") derivations)}
#         '';
#       replacements = {
#         # JVM
#         launcher_name = "nixcraft";
#         launcher_version = "31";

#         classpath = builtins.concatStringsSep ":" libraries;
#         classpath_separator = ":";
#         library_directory = builtins.toString
#           (joinIntoDirectory "minecraft-java-libraries" libraries);

#         natives_directory = ".minecraft/versions/${versionManifest.id}";
#         primary_jar = builtins.toString mainJar;
#         game_directory = ".minecraft";

#         # Game
#         auth_player_name = "hehe";
#         version_name = versionManifest.id;
#         version_type = versionManifest.type;
#         assets_root = "";
#         assets_index_name = "";
#         auth_uuid = "bdb481f7-6f12-4213-af6c-5d96d3b84556";
#         user_type = "mojang";
#       };
#     in map (builtins.replaceStrings
#       (map (var: "\${${var}}") (builtins.attrNames replacements))
#       (builtins.attrValues replacements)) args;

#   processRawArgumentList = argumentListType: rawArgumentList:
#     giveVariables (builtins.concatMap processRawArgument rawArgumentList);
# in builtins.mapAttrs processRawArgumentList versionManifest.arguments;
