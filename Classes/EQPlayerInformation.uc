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

class EQPlayerInformation extends Actor dependson (UniqueIdentifier);

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

 /** Number of teamkills */
 var    int             TeamKills;

 /*
 * DM (personal) type variables
 * TODO: Think about vehicles and stuff
 */

 /** Total score of the player */
 var    float           Score;

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
 var   string           EQIdentifier;


 /*
 * Some more information
 */

 /** Some sprees */
 var    int             FragSpree;
 var    int             CoverSpree;
 var    int             SpawnKillSpree;
 var    float           PlayerScore;

 /** Total time played in seconds */
 var       int       TimePlayedHours;
 var       int       TimePlayedMinutes;
 var       int       StartTime;

 /*
 *  For Mutator's internal purposes only. Not to be sent to backend!
 */

 /** Player's replicationifo */
 //var    PlayerReplicationInfo             EQPRI;

 /** This player killed the enemy FC at this distance from enemy flag */
 var      vector                              KilledFCAtLocation;

 /** UniqueIdentifer reference */
 var       UniqueIdentifier                   EQUID;

 /**
 * The function gets called just after ActorSpawns.
 * So we do the necessary preparations here
 *
 * @since 0.2.0
 */

 function PostBeginPlay()
 {
	if(Owner == none || PlayerReplicationInfo(Owner) == none)
	{
		super.PostBeginPlay();
		return;
	}

	if(PlayerReplicationInfo(Owner).bBot)
	{
		EQIdentifier = "BOT";
	}
	else
	{
		SetTimer(1.f, true);
	}

	StartTime = Level.TimeSeconds;

	super.PostBeginPlay();
 }

/**
 * Here we update the score and match with that of PlayerReplicationInfo
 *
 * @since 0.2.0
 */

 function UpdateScore()
 {
	if(Owner == none || PlayerReplicationInfo(Owner) == none)
	{
		return;
	}

	Score = PlayerReplicationInfo(Owner).Score;
	PlayerController(Controller(PlayerReplicationInfo(Owner).Owner)).ClientMessage("EQPlayerInformation Score Updated to "$Score);
 }

 /**
 * Method to associate UniqueIdentifier reference
 *
 * @since 0.2.0
 */

 function SetUniqueIdentifierReference(Actor UID)
 {
	EQUID = UniqueIdentifier(UID);
	if(EQUID == none)
	{
		Log("Could not associate UniqueIdentifier in EQPlayerInformation", 'Equalizer');
	}
 }

/**
 * Here we do the necessary computations when a player
 * chooses to become spectator
 *
 * @since 0.2.0
 */

 function PlayerBecameSpectator()
 {
	local int Seconds;

	Seconds = Level.TimeSeconds - StartTime;
	TimePlayedMinutes = Seconds / 60;
	TimePlayedHours = TimePlayedMinutes / 60;
	Seconds = Seconds - ( TimePlayedMinutes * 60 );
	TimePlayedMinutes = TimePlayedMinutes - ( TimePlayedHours * 60 );
	
	PlayerController(Controller(PlayerReplicationInfo(Owner).Owner)).ClientMessage("Marking the spectator start epoch!");
 }

/**
 * Here we do the necessary chores when spectator
 * chooses to become a player
 *
 * @since 0.2.0
 */

 function SpectatorBecamePlayer()
 {
	StartTime = Level.TimeSeconds;
	PlayerController(Controller(PlayerReplicationInfo(Owner).Owner)).ClientMessage("Marking the player start epoch!");
 }

/**
 * Standard Timer function.
 *
 * @since 0.2.0
 */

 event Timer()
 {
	if(EQIdentifier ~= "")
	{
		EQIdentifier = EQUID.GetIdentifierString(PlayerReplicationInfo(Owner).PlayerID);
	}
	else
	{
		SetTimer(0.f, false);
	}
 }
