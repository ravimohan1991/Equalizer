/*
 *   --------------------------
 *  |  Equalizer.uc
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
 * Equalizer is a Mutator which makes sure that the CTF matches are 		<br />
 * played between teams of equal calibre. It will further acknowledge and   <br />
 * encourage the team gameplay leading to a justly competitive match.		<br />
 * The aim is to gauge the match awareness, reactivity and commitment		<br />
 * towards CTF goals.								<br />
 *
 * @author The_Cowboy
 * @since 0.1.0
 */

class Equalizer extends Mutator config(Equalizer);

/* Structures */

 /**
 * CTF specific and other useful player information
 *
 * @since 0.1.0
 */
 struct EQPlayerInformation
 {
 	/*
 	* CTF (teambased) type variables
 	*/

 	/** Number of flag captures */
 	var    int				Captures;

 	/** Number of flag grabs */
 	var    int             Grabs;

 	/** Number of flag carrier covers */
 	var    int             Covers;                 // Number of covers. Universal, nah joking. Universal Covers exist in Geometry only.

 	/** Number of base seals */
 	var    int             Seals;

 	/** Number of flag carrier kills */
 	var    int             FlagKills;

 	/*
 	* DM (personal) type variables (Replicated)
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

 	/** Player's name with the Nation prefix, e.g The_Cowboy(IN) */
 	var    string          EQPlayerName;

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

 	/** Player's identification number for a match */
 	var    int             SPlayerID;
 };

/*
 * Global Variables
 */

 /** String with Version of the Mutator */
 var   string                                     Version;

 /** Number of times Equalizer has been built */
 var   float                                      BuildNumber;

 /** Equalizer PlayerInformation structure array */
 var   array<EQPlayerInformation>                 EQPlayers;

 /*
  * Configurable Variables
  */

 var()   config           bool         bActivated;

/**
 * The function gets called just after game begins. So we set up the
 * environmnet for Equalizer to operate.
 *
 * @since version 0.1.0
 */

 function PostBeginPlay()
 {
 	local EQGameRules EQGRules;

 	Log("Equalizer (v"$Version$") Initialized!", 'Equalizer');
 	EQGRules = Level.Game.Spawn(class'EQGameRules'); // for accessing PreventDeath function
 	EQGRules.EQMut = self;
 	Level.Game.AddGameModifier(EQGRules);// register the GameRules Modifier
 }

/**
 * Method to evaluate Covers, Seals and all that.
 *
 * @param Killed The Pawn class getting screwed.
 * @param Killer The Controller class screwing around.
 * @param damageType The nature of damage.
 * @param HitLocation The place of crime.
 *
 * TODO: Rigorously test the Cover/Seal Hypothesis
 *
 * @see #EQGameRules.PreventDeath(Killed, Killer, damageType, HitLocation)
 * @since version 0.1.0
 * authors of this routine can be found at http://wiki.unrealadmin.org/SmartCTF
 */

 function EvaluateKillingEvent(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
 {
  	Log("Killed "$Killed.PlayerReplicationInfo.PlayerName$" Killer "$Killer.PlayerReplicationInfo.PlayerName, 'Equalizer');
 }


 defaultproperties
 {
    Version="0.1.0"
    BuildNumber=14
    Description="Equalizes and encourages CTF team gameplay."
    FriendlyName="DivineIntervention"
 }
