# Equalizer
A UT2004 mutator to equalize CTF teams.

## Tenet
A healthy competition is the one which is just and objective oriented.

## Features
The aim is to encourage the CTF team gameplay and balance the team using a metric. Equalizer acknowledges and measures what denotes overall match awareness, reactivity and commitment towards CTF goals. As of now, the following features are implemented

- CTF Statistics
  - Covers
  - FlagKills
  - Seals
- Broadcasting Events
  - MonsterKills and above
  - Covers/Seals
- Rewards
  - Configurable points and adrenaline for Covers/Seals
- FlagCarrier's location on HUD
- A SQL database backend for accepting and providing the above statistics.
- Parametrized balancing algorithm

There is a long TODO list for balancing teams
- Spawnkill detection?
- If teams get uneven during the match (e.g. due to leaving players), rebalancing by size (like the private code in Miasma) can be triggered either automatically or on player request
- WebAdmin support?

## Configuration
The configurable variables can be found in Equalizer.ini. If it is not provided in the package, it will be generated after the first run.

INI setting | Default value | Description
------------|---------------|-------------
`Version` | [Semantic Versioning](https://semver.org) | Version string for internal/external interfacing.
`BuildNumber` | Date-Time-Number | Integer for avoiding file mismatches on heavy experimenting.
`Description` | Equalizes and encourages CTF team gameplay. | The essence of the Mutator.
`FriendlyName` | DivineIntervention | Name displayed in-game.
`CoverReward` | 2 | Reward to be given on providing a successful cover.
`CoverAdrenalineUnits` | 5 | Adrenaline given on successful cover.
`SealAward` | 2 | When your flag is at home (untouched) and you cover your FC within certain distance from your flag.
`SealAdrenalineUnits` | 5 | Adrenaline given on successful Seal.
`SealDistance` | 2200 | The radius of the imaginary bubble around the flag for evaluating Seals.
`bShowFCLocation` | true | If set to true, your FC location will be shown in your HUD.
`FCProgressKillBonus` | 4 | ???
`bBroadcastMonsterKillsAndAbove` | true | If you want to have global broadcast for achieveing MonsterKill or above.
`UniqueIdentifierClass` | Equalizer.UniqueIdentifierClass | The \<PackageName\>.\<ClassName\> for the serverside class. See [UniqueIdentifier](https://github.com/ravimohan1991/Equalizer/blob/main/UniqueIdentifier.md) for more details.
`TeamSizeBalancerClass` | Equalizer.TeamSizeBalancer | The interface for external balancer code (courtsey Piglet(UK)).
`QueryServerHost` | localhost | The hostname string.
`QueryServerfilePath` | /EqualizerBE/eqquery.php | The relative path string of the BackEnd PHP scripts.
`QueryServerPort` | 80 | The port leveraged for queries.
`MaxTimeout`| 10 | The time in seconds afte which to retry.
`bLogTeamsRollCall` | true | Logging the team players. For debugging purposes.
`bShowTeamsRollCall`| false | Showing the team players in game console?
`BalanceMethod` | 0 | The order determination parameter.
`MinimumtimePlayed` | 30 | ???
`bBalanceAtMapStart` | true | Should Equalizer balance teams at the start of the map?
`bMidGameMonitoring`| false | ?
`bDebugIt` | true | Various logging for debugging purposes.
`LogCompanionTag` | Equalizer | The string with which the logs generated by Equalizer are to be tagged.

  ### Acronyms
  FC: Flag Carrier (The player who is carrying the flag)

## Installation
Please refer [Installation](https://github.com/ravimohan1991/Equalizer/blob/miasmactivity/Installation.md) document.

## Balancing 
At this point in time, the Balancing algorithm is fleshed out in full details [here](https://github.com/ravimohan1991/Equalizer/blob/miasmactivity/BalancingAlgorithm.md).

## Caveats
- The if player starts spectating after returning the flag then the additional score (3, 5 or 7) will not be taken into account for PPH computations. It is due to the [Epic's code](http://wormbo.de/uncodex/ut2004/Source_unrealgame/ctfgame.html#192) hooking appropriately is not possible.

## Credits and Thanks
In alphabetical order
- [Miasma Forums](https://miasma.rocks)
- People of India
- Piglet
- SmartCTF [creators](http://wiki.unrealadmin.org/SmartCTF)
- Wormbo 
