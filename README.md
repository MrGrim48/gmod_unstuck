# Unstuck
A gamemode agnostic solution to Garry's Mod players getting stuck, with Dark RP implementations included.

This unstuck addon is a heavily modified version of another that was posted on facepunch some time ago.

## Installation
To install the addon, simply place add this to your addons folder on your server.

## Configuration
Configuration is in the sh_unstuck.lua file. In this file, the command can be changed as well as it's prefix. The usergroups that should be treated as having moderator privileges by the addon may also be changed. This setting ensures that no ordinary players may gain access to information that may give them an advantage or an aid to exploit with this addon.

Other more in-depth configuration properties may also be found in this file, such as whether or not the addon should respawn a player if it fails in its attempts to find a suitable location to place the player if they are stuck, and the wait duration between the notification of this and the player being respawned.

A cooldown period may also be set, in seconds, for how often a player may call the command. by default this is set at 5 seconds. The last configurable property is called "Max Depth". This refers to how hard the addon should try to find a location for the player if they are stuck before returning no solution. Increasing this value will allow the addon to find more suitable places to put the player, however it will also increase the computational expense of doing so.

## Usage
To notify the addon that a given player is stuck, said player must enter into the chatbox a prefix and a command both defined in the configuration file. By default, the prefixes allow are "!" and "/", and the commands allowed are "stuck" and "unstuck". 

If this addon doesn't detect the chat commands used, it is possible that another addon, also listening for chat commands, could be interfering. If this is the case, attempt first to alter the prefix to one known not to be used by another addon. Please note that prefixes may as of currently only be 1 character long.

If the addon fails to locate a suitable place to put the player, as mentioned in the configuration section, the addon will respawn the player, if the configuration allows this.
