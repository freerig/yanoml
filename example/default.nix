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
      ];
  };
}
