# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added 

- Changelog
- Tracking spawnkills, teamkills and suicides
- A backend for accepting the above statistics along with (points per hour) PPH and comeup with a player rating points (PRP)
- Teams can be shuffled at match start in a way that tries to balance the potential team skill on both sides by aiming for only little difference in combined PRP for the players on each team
- Particularly short first rounds (e.g. caused by skilled players joining shortly after match start) can be reset with another team shuffling and PRP balancing
- Players that join the match can be put specifically on the team that needs additional players
- Players attempting to switch to the winning team can be forced to switch back to their original team
- If teams get uneven during the match (e.g. due to leaving players), rebalancing by size can be triggered either automatically or on player request

### Fixed

- Accessed none warnings [\#1](https://github.com/ravimohan1991/Equalizer/issues/1)


## [0.1.0-alpha] - 2021-05-19

### Initial Release

[unreleased]: https://github.com/ravimohan1991/Equalizer/compare/v0.1.0-alpha...HEAD
[0.1.0-alpha]: https://github.com/ravimohan1991/Equalizer/releases/tag/v0.1.0-alpha

