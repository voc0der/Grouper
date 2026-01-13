# Grouper

WoW Classic addon for managing PUG groups for raids, dungeons, and world bosses.

**Supports Classic, TBC, and WOTLK!** Automatically detects your expansion and provides appropriate content.

## Features

- **Multi-Expansion Support** - Works on Classic, TBC, and WOTLK with auto-detection
- **Graphical UI** - Full configuration interface accessible via `/grouper`
- **100+ Dungeons & Raids** - Pre-configured for all content from 5-mans to 40-man raids
- **Automatic World Boss Kill Tracking** - Detects boss kills and records them with layer info
- **Smart Messaging** - Auto-generates recruitment messages based on your raid composition
- **Minimap Button** - Quick access to configuration (draggable, can be hidden)
- **Channel Spam Buttons** - Click to post to Trade (in cities), LFG, or General channels
- **Configurable** - Set custom tank/healer requirements, hard reserves, raid sizes, and spam intervals per boss/dungeon
- **Nova World Buffs Integration** - Automatic layer detection for kill tracking

## Install

Copy `Grouper` folder to your AddOns directory:
- Classic: `World of Warcraft/_classic_/Interface/AddOns/`
- TBC: `World of Warcraft/_classic_/Interface/AddOns/`
- WOTLK: `World of Warcraft/_classic_/Interface/AddOns/`

Or install from CurseForge: [Grouper](https://www.curseforge.com/wow/addons/grouper)

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