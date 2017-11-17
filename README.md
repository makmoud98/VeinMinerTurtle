some lua code for a mining 'turtle' in the ComputerCraft minecraft mod http://www.computercraft.info
i would deploy mutiple bots running mine.lua that waited for a command from listen.lua
update.lua was used to update the bot code by downloading from my web server. this way, i could write code from my text editor instead of inside of minecraft.

-implemented a recursive function that was used to mine a vein of ore. 
-it used coal that it mined to refuel itself while also returning to a chest to deposit ores.
-listen for a command from the main bot after completing its run
