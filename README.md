# Grouper

WoW Classic addon for managing PUG groups for raids, dungeons, and world bosses.

## Features

- **Graphical UI** - Full configuration interface accessible via `/grouper`
- **40+ Dungeons & Raids** - Pre-configured for all Classic content from 5-mans to 40-man raids
- **Smart Messaging** - Auto-generates recruitment messages based on your raid composition
- **Minimap Button** - Quick access to configuration (draggable, can be hidden)
- **Channel Spam Buttons** - Click to post to Trade (in cities) or LFG channels
- **Configurable** - Set custom tank/healer requirements, hard reserves, raid sizes, and spam intervals per boss/dungeon

## Install

Copy `Grouper` folder to `World of Warcraft/_classic_/Interface/AddOns/`

Or use CurseBreaker: `install https://github.com/voc0der/Grouper`

On Curse as `Grouper-Classic`.

## Quick Start

Click minimap icon to open the GUI, or type:
```
/grouper
```

Select your boss/dungeon, configure settings, and click "Start Recruiting".

## Chat Commands (Optional)

Open the configuration GUI:
```
/grouper
```

Get help:
```
/grouper help
```

Start recruiting (GUI recommended):
```
/grouper azuregos
/grouper azuregos Mature Blue Dragon Sinew
```

Stop recruiting:
```
/grouper off
```

Toggle minimap button:
```
/grouper minimap
```

Advanced settings (or use the GUI):
```
/grouper set raidsize 40
/grouper set tank azuregos 2
/grouper set healer kazzak 8
/grouper set hr azuregos Mature Blue Dragon Sinew
/grouper set tradeinterval 300
/grouper set lfginterval 300
```