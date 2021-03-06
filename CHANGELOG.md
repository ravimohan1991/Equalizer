# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added 

- Changelog
- Tracking spawnkills and teamkills 
- UniqueIdentifier scheme, as suggested by Piglet ([154b235](https://github.com/ravimohan1991/Equalizer/commit/154b235452e8d6ca79858ba0930beeabcfd3d0c0))
- Tracking spawnkills, teamkills and suicides
- A backend for accepting the above statistics along with (points per hour) PPH and comeup with a player rating points (PRP)
- Teams can be shuffled at match start in a way that tries to balance the potential team skill on both sides by aiming for only little difference in combined PRP for the players on each team
- Particularly short first rounds (e.g. caused by skilled players joining shortly after match start) can be reset with another team shuffling and PRP balancing
- Players that join the match can be put specifically on the team that needs additional players
- Players attempting to switch to the winning team can be forced to switch back to their original team
- If teams get uneven during the match (e.g. due to leaving players), rebalancing by size can be triggered either automatically or on player request


## [0.2.0] - 2021-09-04

### Added

- Changelog
- UniqueIdentifier scheme, as suggested by Piglet ([154b235](https://github.com/ravimohan1991/Equalizer/commit/154b235452e8d6ca79858ba0930beeabcfd3d0c0))
- Tracking suicides
- A backend for accepting relevant Equalizer information and memorize in appropriate database

### Fixed

- Accessed none warnings [\#1](https://github.com/ravimohan1991/Equalizer/issues/1)

## [0.1.0-alpha] - 2021-05-19

### Initial Release

[unreleased]: https://github.com/ravimohan1991/Equalizer/compare/v0.1.0-alpha...HEAD
[0.1.0-alpha]: https://github.com/ravimohan1991/Equalizer/releases/tag/v0.1.0-alpha
[0.2.0]: https://github.com/ravimohan1991/Equalizer/releases/tag/v0.2.0

