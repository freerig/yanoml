inputs:

let inherit (inputs) pkgs lib;
in rec {
  nu = {
    # Use this function if your script doesn't need to use other scripts (no `use ./lib.nu`)
    writeSimpleNushellScript = name: script:
      pkgs.writeTextFile {
        inherit name;
        executable = true;
        text = ''
          #!${lib.getExe pkgs.nushell}

          ${script}
        '';
      };

    # Use this to allow the script to access local files
    writeNushellScriptDir = name:
      { rootDir, inputs ? null }:
      pkgs.runCommand "${name}-root" { } ''
        mkdir -p $out
        cp -r ${rootDir}/* $out
        ls $out
        ln -s ${
          pkgs.writeText "inputs.json" (builtins.toJSON inputs)
        } $out/inputs.json
      '';
    wrapNushellFileBin = name: path:
      pkgs.writeTextFile {
        inherit name;
        executable = true;
        destination = "/bin/${name}";
        text = ''
          #!${lib.getExe pkgs.nushell}

          source ${path}
        '';
        meta.mainProgram = name;
      };
  };

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
