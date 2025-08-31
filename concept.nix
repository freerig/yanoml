let
  # ParesedMeta
  minecraftMeta = {
    client = {
      mainClass = "<main class huh>";

      libraries = [{
        jar = "jar file";
        natives = [
          # natives
        ];
      }];

      arguments = {
        jvm = {
          raw = [ ]; # raw args, with ${var}
          # maybe this will be a place to add features, rules...
        };
        game = "<same>";
      };

      assets = {
        id = 17;
        index = {
          objects = {
            "icons/..." = {
              hash = "";
              # ...
            };
          };
        };
        files = {
          "<hash>" = "<file>";
          # downloaded assets
        };
      };
    };

    server = {
      # main
    };
  };
in false
