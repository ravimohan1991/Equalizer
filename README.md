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

Some more statistics including teamkills and suicides are on TODO list.

There is a long TODO list for balancing teams
- A backend for accepting the above statistics along with (points per hour) PPH and comeup with a player rating points (PRP)
- Teams can be shuffled at match start in a way that tries to balance the potential team skill on both sides by aiming for only little difference in combined PRP for the players on each team
- Particularly short first rounds (e.g. caused by skilled players joining shortly after match start) can be reset with another team shuffling and PRP balancing
- Players that join the match can be put specifically on the team that needs additional players
- Players attempting to switch to the winning team can be forced to switch back to their original team
- If teams get uneven during the match (e.g. due to leaving players), rebalancing by size can be triggered either automatically or on player request
- WebAdmin support?

## Configuration
The configurable variables can be found in Equalizer.ini. If it is not provided in the package, it will be generated after the first run.
INI setting | Default value | Description
------------|---------------|-------------
`CoverReward` | 2 | Reward to be given on providing a successful cover.
`CoverAdrenalineUnits` | 5 | Adrenaline given on successful cover.
`SealAward` | 2 | When your flag is at home (untouched) and you cover your FC within certain distance from your flag.
`SealAdrenalineUnits` | 5 | Adrenaline given on successful Seal.
`SealDistance` | 2200 | The radius of the imaginary bubble around the flag for evaluating Seals.
`bShowFCLocation` | true | If set to true, your FC location will be shown in your HUD.
`bBroadcastMonsterKillsAndAbove` | true | If you want to have global broadcast for achieveing MonsterKill or above.
  ### Acronyms
  FC: Flag Carrier (The player who is carrying the flag)

## Installation


