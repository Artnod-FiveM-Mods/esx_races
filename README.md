[![GitHub license](https://img.shields.io/github/license/Artnod-FiveM-Mods/esx_races.svg)](https://github.com/Artnod-FiveM-Mods/esx_races/blob/master/LICENSE) :small_blue_diamond: 
[![Discord](https://img.shields.io/discord/436197783863558164.svg)](https://discord.gg/u7dj7Ja)  

# esx_races
This is a Grand Theft Auto V mod that implements Singleplayer street races and Multiplayer street races, with ranking.  

Mod for CitizenFx server (FiveM server).  

Singleplayer street races with ranking. 
  - Colect item in area
    - Need cops in the city
    - Cops can't collect
  - Register for a race in other area
    - Need one collected item
    - Need cops in the city
  - Run race
    - Freeze vehicle at startup
    - Chronometer
    - Loose race after time out of vehicle
    - Checkpoints list
  - Ranking same area than register
    - Own ranking
    - Top 6 Daily
    - Top 6 Monthly


Multiplayers street races with ranking.
  - Colect item in area
    - Need cops in the city
    - Cops can't collect
  - Create a race in other area
    - Need one collected item
    - Can edit nb laps and racers
    - Can open/close registration
    - Can start/stop/remove race
  - Register same area than Create
    - Need one collected item
    - Need cops in the city
    - Can select created race with opened registration 
  - Run race
    - Freeze vehicle at startup wait all racer
    - Chronometer
    - Loose race after time out of vehicle
    - Checkpoints list
  - Ranking same area than register
    - Own ranking
    - Top 6 Daily
    - Top 6 Monthly



[SinglePlayer youtube sample](https://gaming.youtube.com/watch?v=8cwoR1DLpC8)  
[MultiPlayer youtube sample](https://gaming.youtube.com/watch?v=ZhFSVzA7HvQ)  

## Requirements
 - [esx_policejob](https://github.com/ESX-Org/esx_policejob)

## Download & Installation

### Manually
- Download https://github.com/Artnod-FiveM-Mods/esx_races/archive/master.zip
- Put it in the `[esx]` directory

## Installation
- Import `esx_races.sql` in your database
- Add this in your `server.cfg`:

```
start esx_races
```

# Legal
### License
Artnod-FiveM-Mods/esx_races  

This program is licensed under the GNU General Public License v3.0  

Permissions of this strong copyleft license are conditioned on making available complete source code of licensed works and modifications, which include larger works using a licensed work, under the same license.  

Copyright and license notices must be preserved. Contributors provide an express grant of patent rights.
