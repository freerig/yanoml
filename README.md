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
   (don't forget to replace 1.21.1 with the version of your choice).
   You should get a `repo.json` file in the working directory.
   Find more infos in [the documentation](#change-runtime-props-).

2. Once you have your repo, you can write a flake like that:
   ```nix
   {
     description = "My Minecraft Client";
     inputs.yanoml.url = "github:freerig/yanoml";
     outputs = { self, yanoml }:
       let system = "x86_64-linux";
       in {
         packages.${system} = rec {
           my-great-minecraft-client = yanoml.mkMinecraftClient.${system} {
             minecraftVersion = "1.21.1";
             repoFile = ./repo.json;
           };
           default = my-great-minecraft-client;
         };
       };
   }
   ```

## Documentation

### Change runtime props (username, gamedir...)

Just type `nix run github:freerig/yanoml#examples.basic -- --help` to see more options!

### Create/manage a `repo.json`

These commands will be applied to `$PWD/repo.json` (this file will be created if it doesn't exist already). Don't forget to change the command parameters to reflect your needs. **All these commands have a `--help` menu.**
- Add a vanilla Minecraft version: `nix run github:freerig/yanoml#repo.vanilla.add-minecraft -- 1.21.1`
- Add Fabric (Forge isn't supported right now):
  ```shell
  nix run github:freerig/yanoml#repo.vanilla.add-minecraft -- 1.21.1 # Fabric needs vanilla to work!
  nix run github:freerig/yanoml#repo.fabric.add-minecraft -- 1.21.1 # Fabric needs an intermediary lib for each Minecraft version it will run on.
  nix run github:freerig/yanoml#repo.fabric.add-loader -- 0.17.2 # This is to install the Fabric loader (kinda the core of Fabric).
  ```
- Add a mod (only Modrinth is currently supported):
  `nix run github:freerig/yanoml#repo.mods.add-mod -- nvQzSEkH -v 1.21.1 -l fabric -L`
  This adds the latest version of the [Jade](https://modrinth.com/mod/jade) mod that is compatible with Fabric running Minecraft `1.21.1`. You can find the mod id (in this case `nvQzSEkH`) by clicking the three points button at the top left of the Modrinth mod page and then selecting "Copy ID".

### Create a package from my `repo.json`

The documentation isn't ready right now, but you can find some examples in the `examples` directory. If you need help, ask for it in the GitHub discussions page!

## Q&A

### There isn't any .minecraft/mods dir but mods still works, how?

That's real magic.

### Will ... be implemented?

Maybe, check on the GitHub issues and discussions to see. If you find nothing, leave one!

### I have a problem with...

You can either leave an issue or open a discussion, your choice.

### Can I get some mods with this?

Yes, but it only supports Fabric for now (Quilt, Forge and others will come one day). `nix run github:freerig/yanoml#examples.fabric` allows you to run a Minecraft Fabric client with [Fabric API](https://modrinth.com/mod/fabric-api), [Immersive Portals](https://modrinth.com/mod/immersiveportals), [Pehkui](https://modrinth.com/mod/pehkui), [Jade](https://modrinth.com/mod/jade) and [Mod Menu](https://modrinth.com/mod/modmenu) installed.

### Is it any good?

[yes.](https://helix-editor.com/#:~:text=Is%20it%20any%20good?-,Yes.) (link to a link brrr)

### How do I log in?

Not yet ready...

### Your project sucks.

No it doesn't lol, but you can always propose some improvements in the discussions or issues!
