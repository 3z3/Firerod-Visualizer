# Firerod-Visualizer
*Tile Visualizer for the Firerod ROM hack of Zelda The Minish Cap*

### Historical Background and Context

The Firerod is an item that appears in many games of The Legend of Zelda license and was scrapped during the development of The Minish Cap, its texture still appears on the item with id `0x16` which you can verify by opening an emulator of the game and modifying the memory value at the address `0x2af4` in EWRAM (or simply the address `0x02002af4` in the System Bus) to the corresponding id `0x16`; this will grant you the Firerod developper tool on your A button.
Indeed the functionality of the item itself was scrapped but it still served as a helping tool for people testing the game during development, or so we assume.

### Functionality of the Firerod

This version of the Firerod does not launch fire balls where it is pointed, but copies, pastes and cycles tiles Link walks on.
Tiles are the universal way of subdividing space in retro games, they are little building blocks which made up the environment of most 2D games back then, their properties can influence the illusion of perspective, depth and are used to define collision (where the player can go, what are walls, what aren't walls, where the ground is, etc), as it is done in The Minish Cap.

Coming back to how the Firerod works in TMC, most of the time, a tile in game is characterized by an id which the Firerod can copy by pressing and holding the A button, this id is a 2 byte number (ranging from `0x0` to `0xffff`, or 65535) and it can be modified, or "cycled" through by pressing or holding left or right while holding the A button, pressing left will increase the value of the id, and pressing right will decrease it.
Releasing the A button will paste a default tile corresponding to whichever id was last copied the first frame after unpressing it.
For example, id `0x73` will be a closed chest which you can interact with in all areas, and id `0xfffa` will be an invisible tile which can be used to get onto layer 2.
Finally, pressing B while doing all of the previous actions will paste 4 tiles in every cardinal direction next to Link, and pressing R while holding A will lock the copied id and let Link move left and right without modifying it.

While holding a direction when using the Firerod, if R is not being pressed, the id will cycle once from the first time the direction is held, and will continue cycling once every frame after 32 frames of holding that same direction.
Picking up a tile that looks like it has a glitchy texture in an area will often end up picking up the wrong id `0xffff`, most other quirks of the Firerod can be experimented on by testing it out during gameplay.

## What the Script does

This Lua script is originally made for the Bizhawk emulator, which can emulate The Minish Cap, and has a Lua scripting integration which can be helpful for looking into the game's memory during gameplay and modifying it live, among other things.
This script is meant as a learning tool to better understand how to use the firerod, and how different tiles relate to each other in id order, this is made simpler by displaying what the copied tile id looks like graphically when using the Firerod (before having to paste it onto the ground) and by having other useful information available on screen, like the copied id, or the collision value the copied tile has (which can sometimes be used to test other properties, like whether a tile is a ladder, a rock wall, a loading zone, etc).

## HOW TO USE

Like most Lua scripts for Bizhawk :
Open Bizhawk 2.9.1 and higher versions, load your Minish Cap ROM (or Firerod ROM hack of the game) -> Go to Tools -> Lua Console -> Open Script -> `firerod_data.lua`
And make sure your game is unpaused, when playing, if you copy a tile with the Firerod, you will see it appear on the bottom right corner of the screen with information about collision and id.
