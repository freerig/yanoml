inputs:

rec {
  inherit (inputs) pkgs lib;
  writeNushellScript = name: data: script:
    pkgs.writeShellScript name ''
      ${pkgs.coreutils}/bin/env ${
        lib.strings.escapeShellArg "INPUT=${builtins.toJSON data}"
      } ${lib.getExe pkgs.nushell} ${pkgs.writeText "${name}.nu" script}
    '';

  joinIntoDirectory = name: derivations:
    pkgs.runCommand name { } ''
      mkdir -p $out
      ${builtins.concatStringsSep "\n"
      (map (d: "ln -fs ${d} $out/${d.name}") derivations)}
    '';

  joinIntoDirectoryAttr = name: attr:
    pkgs.runCommand name { } ''
      mkdir -p $out
      ${builtins.concatStringsSep "\n" (map (name: ''
        mkdir -p $out/${builtins.dirOf name}
        ln -s ${attr.${name}} $out/${name}
      '') (builtins.attrNames attr))}
    '';

  getJSON = file: builtins.fromJSON (builtins.readFile file);
  fetchJSON = fetchParams: getJSON (pkgs.fetchurl fetchParams);
}
