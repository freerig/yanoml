inputs:
{ self, system }:

{
  basic = self.mkMinecraftClient.${system} {
    minecraftVersion = "1.21.1";
    repoFile = ./repo.json;
  };
  fabric = self.mkMinecraftClient.${system} {
    minecraftVersion = "1.21.1";
    repoFile = ./repo.json;
    modLoader = "fabric";
    modLoaderVersion = "0.17.2";
    modPredicate = mods:
      with mods; [
        fabric-api."0.116.6+1.21.1"
        immersiveportals."v6.0.6-mc1.21.1"
        jade."15.10.2+fabric"
        pehkui."3.8.3+1.14.4-1.21"
        modmenu."11.0.3"
        # You can add your own JARs right here! It can be a derivation, a file, or a mod from the function input like above.
      ];
  };
}
