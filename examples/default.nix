inputs:
{ self, system }:

let
  modPredicate = mods:
    with mods; [
      fabric-api."0.116.6+1.21.1"
      sodium."mc1.21.1-0.6.0-fabric"
      immersiveportals."v6.0.6-mc1.21.1"
      jade."15.10.2+fabric"
      pehkui."3.8.3+1.14.4-1.21"
      modmenu."11.0.3"
      # You can add your own JARs right here! It can be a derivation, a file, or a mod from the function input like above.
    ];
in {
  basic = self.mkMinecraft.${system} {
    minecraftVersion = "1.21.1";
    repoFile = ./repo.json;
  };
  # (You can use the basic.client or basic.server packages)

  fabric = self.mkMinecraft.${system} {
    minecraftVersion = "1.21.1";
    repoFile = ./repo.json;
    modLoader = "fabric";
    modLoaderVersion = "0.17.2";
    inherit modPredicate;
  };

  quilt = self.mkMinecraft.${system} {
    minecraftVersion = "1.21.1";
    repoFile = ./repo.json;
    modLoader = "quilt";
    modLoaderVersion = "0.29.1";
    inherit modPredicate;
  };
}
