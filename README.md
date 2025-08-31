<h1 align="center"> YANOML </h1>
<p align="center"> <b>Y</b>et <b>A</b>nother <b>N</b>ix <b>O</b>verfine <b>M</b>inecraft <b>L</b>auncher </p>

Tired of not being able to take advantage of the Nix store to play Minecraft? Tired of installing Fabric manually, and copying the mod files from the .zip your non-existent friend sent you? I got *the* solution for you: *YANOML*.

## So how do I test your thing because idk if it's really good?

It is really good, but if you really want a proof, you can follow the following steps to run Minecraft 1.21.1:

1. (Optional) If you don't wanna spend half an hour looking at Nix downloading assets, you can type:
   ```shell
   nix run github:freerig/yanoml#prefetch -- 1.21.1
   ```
   This will prefetch all the assets of Minecraft 1.21.1 and put them into your Nix store, just for you! It can take some time, so be patient.

2. Just run the game like that:
   ```shell
   nix run github:freerig/yanoml#examples.basic
   ```
   If it doesn't work and you don't know what you are doing wrong, please leave an issue or open a discussion.

## Now I know it's really good, and I wanna make a flake of it

1. To make your own client, you need a `repo.json`. This file contains all the hashes of the files that the loader needs. You can create your own repo by adding a minecraft version to it like that:
   ```shell
   nix run github:freerig/yanoml#repo.vanilla.add-minecraft 1.21.1
   ```
   (don't forget to replace 1.21.1 with the version of your choice)
   You should get a `repo.json` file in the working directory.

2. Once you have your repo, you can write a flake like that:
   ```nix
   {
     description = "My Minecraft Client";
     inputs.yanoml.url = "github:freerig/yanoml";
     outputs = { self, yanoml }:
       let
         system = "x86_64-linux";
       in {
         packages.${system}.my-great-minecraft-client =
           yanoml.mkMinecraftClient.${system} { minecraftVersion = "1.21.1"; repoFile = ./repo.json; };

         packages.${system}.default = self.packages.${system}.my-great-minecraft-client;
       };
   }
   ```

## Q&A

### I have a problem with...

You can either leave an issue or open a discussion, your choice.

### Is it any good?

[yes.](https://helix-editor.com/#:~:text=Is%20it%20any%20good?-,Yes.) (link to a link brrr)
