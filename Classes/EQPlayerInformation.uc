/*
 *   --------------------------
 *  |  EQPlayerInformation.uc
 *   --------------------------
 *   This file is part of Equalizer for UT2004.
 *
 *   Equalizer is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   Equalizer is distributed in the hope and belief that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with Equalizer.  if not, see <https://www.gnu.org/licenses/>.
 *
 *   Timeline:
 *   May, 2021: First inscription
 */

/**
 * CTF specific and other useful player information     <br />
 * along with the useful functions
 *
 * @since 0.1.0
 */

class EQPlayerInformation extends Actor;

/*
 * Global Variables
 */

 /*
 * CTF (teambased) type variables
 */

 /** Number of flag captures */
 var    int             Captures;

 /** Number of flag grabs */
 var    int             Grabs;

 /** Number of flag carrier covers */
 var    int             Covers;                 // Number of covers. Universal, nah joking. Universal Covers exist in Geometry only.

 /** Number of base seals */
 var    int             Seals;

 /** Number of flag carrier kills */
 var    int             FlagKills;

 /*
 * DM (personal) type variables
 * TODO: Think about vehicles and stuff
 */

 /** Number of frags */
 var    int             Frags;

 /** Number of headshots */
 var    int             HeadShots;

 /** Number of shieldbelts picked */
 var    int             ShieldBelts;

 /** Number of amplifiers picked */
 var    int             Amps;

 /** Number of suicides */
 var    int             Suicides;

 /** If the player drew the first blood */
 var    bool            bFirstBlood;

 /*
 * Other information
 */

 /** Player's netspeed */
 var    int             NetSpeed;

 /** Player's unique identification number */
 // To be obtained from Piglet
 var   string           EQGuid;


 /*
 * Some more information
 */

 /** Some sprees */
 var    int             FragSpree;
 var    int             CoverSpree;
 var    int             SpawnKillSpree;
 var    float           PlayerScore;

 /*
 *  For Mutator's internal purposes only. Not to be sent to backend!
 */

 /** Player's replicationifo */
 //var    PlayerReplicationInfo             EQPRI;
