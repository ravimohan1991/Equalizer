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
 * Equalizer is a Mutator which makes sure that the CTF matches are			<br />
 * played between teams of equal calibre. It will further acknowledge and	<br />
 * encourage the team gameplay leading to a justly competitive match.		<br />
 * The aim is to gauge the match awareness, reactivity and commitment		<br />
 * towards CTF goals.														<br />
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
 	var    int             EQPlayerID;

 	/** This is not C++ so can't pass null struct */
 	var    bool            bNull;
 };

/*
 * Global Variables
 */

 /** String with Version of the Mutator */
 var   string                                     Version;

 /** Number of times Equalizer has been built */
 var   float                                      BuildNumber;

 /** For tracking the PlayerJoin.*/
 var   int                                        CurrID;

 /** Equalizer PlayerInformation structure array */
 var   array<EQPlayerInformation>                 EQPlayers;

 /** Controller Array of CTF's Flag Carriers.*/
 var   Controller                                 FCs[2];

 /*
  * Configurable Variables
  */

 var()   config           bool         bActivated;
 var()   config           int          CoverReward;
 var()   config           int          CoverAdrenalineUnits;

/**
 * The function gets called just after game begins. So we set up the
 * environmnet for Equalizer to operate.
 *
 * @since 0.1.0
 */

 function PostBeginPlay()
 {
	local EQGameRules EQGRules;
	
	Log("Equalizer (v"$Version$") Initialized!", 'Equalizer');
	SaveConfig();
	EQGRules = Level.Game.Spawn(class'EQGameRules'); // for accessing PreventDeath function
	EQGRules.EQMut = self;
	Level.Game.AddGameModifier(EQGRules);// register the GameRules Modifier
	
	super.PostBeginPlay();
 }

/**
 * Method to register PlayerJoin event.
 * Warning: Only Humans are detected this way
 *
 * @since 0.1.0
 * @see GameInfo.Login
 */

 event Tick(float DeltaTime)
 {

	local Controller Cont;
	
	while(Level.Game.CurrentID > CurrID)
	{
		for(Cont = Level.ControllerList; Cont != none; Cont = Cont.nextController)
		{
			if(PlayerController(Cont) != none && Cont.PlayerReplicationInfo != none && Cont.PlayerReplicationInfo.PlayerID == CurrID)
			{
				PlayerJoin(Cont);
				break;
			}
		}
		CurrID++;
	}
 }

/**
 * The function to check track the bot join.
 *
 * @param Other The Pawn instance of humanplayer or bot
 * @since 0.1.0
 */

 function ModifyPlayer(Pawn Other)
 {
	local Controller BotController;
	local bool bMatchFound;
	local int i;
	
	if(AIController(Other.Controller) != none)
	{
		BotController = Other.Controller;
		for(i = 0; i < EQPlayers.Length; i++)
		{
			if(EQPlayers[i].EQPlayerID == BotController.PlayerReplicationInfo.PlayerID)
			{
				bMatchFound = true;
				break;
			}
		}
	
		if(!bMatchFound)
		{
			PlayerJoin(BotController);
		}
	}
	
	if(NextMutator != None)
		NextMutator.ModifyPlayer(Other);
 }

/**
 * Here, we add the Equalizer marker to the player.
 * It will facilitate the tracking of player stats.
 *
 * @since 0.1.0
 */

 function PlayerJoin(Controller FreshMeat)
 {
	local EQPlayerInformation EQPI;
	
	EQPI.EQPlayerID           = FreshMeat.PlayerReplicationInfo.PlayerID;
	EQPI.EQPlayerName         = FreshMeat.PlayerReplicationInfo.PlayerName;
	
	EQPlayers[EQPlayers.Length] = EQPI;
	
	Log("Started tracking player "$EQPI.EQPlayerName, 'Equalizer');
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
 * TODO: Log teamkills
 * TODO: Coverspree broadcast
 *
 * @see #EQGameRules.PreventDeath(Killed, Killer, damageType, HitLocation)
 * @since 0.1.0
 * authors of this routine can be found at http://wiki.unrealadmin.org/SmartCTF
 */

 function EvaluateKillingEvent(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
 {
	local EQPlayerInformation KillerInfo, KilledInfo;
	local PlayerReplicationInfo KilledPRI, KillerPRI;
	local bool bKilledTeamHasFlag;
	
	if(Killed == none || Killed.Controller == none) return;
	KilledPRI = Killed.PlayerReplicationInfo;
	if(KilledPRI == none || (KilledPRI.bIsSpectator && !KilledPRI.bWaitingPlayer)) return;
	
	KilledInfo = GetInfoByID(Killed.PlayerReplicationInfo.PlayerID);
	
	if(!KilledInfo.bNull)
	{
		KilledInfo.FragSpree = 0;// Reset FragSpree for Victim
		KilledInfo.CoverSpree = 0;
		KilledInfo.SpawnKillSpree = 0;
		Log("Spreecounter cleared", 'Equalizer');
	}
	
	if(Killer == none || Killer == Killed.Controller)
	{
		if(!KilledInfo.bNull) KilledInfo.Suicides++;
		return;
	}
	
	Log("Looking into Killer info", 'Equalizer');
	KillerPRI = Killer.PlayerReplicationInfo;
	if(KillerPRI == none && (KillerPRI.bIsSpectator && !KillerPRI.bWaitingPlayer)) return;
	
	KillerInfo = GetInfoByID(Killer.PlayerReplicationInfo.PlayerID);
	
	if(KilledPRI.Team == KillerPRI.Team)
		return;// Mistakes can happen :) TeamKill logic should be put here
	
	// Increase Frags and FragSpree for Killer
	if(!KillerInfo.bNull)
	{
		Log("Analyzing killer info!", 'Equalizer');
		KillerInfo.Frags++;
		KillerInfo.FragSpree++;
		if(KilledPRI.HasFlag != None)
		{
		  KillerInfo.FlagKills++;
		}
		
		// HeadShot tracking
		if(damageType == Class'UTClassic.DamTypeClassicHeadshot')
		KillerInfo.HeadShots++;
	}
	
	if(KillerPRI.HasFlag == none && FCs[KillerPRI.Team.TeamIndex] != none && FCs[KillerPRI.Team.TeamIndex].PlayerReplicationInfo.HasFlag != none)
	{
		// COVER FRAG  / SEAL BASE
		// if Killer's Team has had an FC
		// if the FC has Flag Right now
		// Defend kill
		// org: if victim can see the FC or is within 600 unreal units (approx 40 feet) and has a line of sight to FC.
		//if( Victim.canSee( FCs[KillerPRI.Team] ) || ( Victim.lineOfSightTo( FCs[KillerPRI.Team] ) && Distance( Victim.Location, FCs[KillerPRI.Team].Location ) < 600 ) )
		// new: Killed was within 512 uu(UT) of FC
		//      or Killer was within 512 uu(UT) of FC
		//      or Killed could see FC and was killed within 1536 uu(UT) of FC
		//      or Killer can see FC and killed Killed within 1024 uu(UT) of FC
		//      or Killed had direct line to FC and was killed within 768 uu(UT)
		//
		// Note:      The new measures probably appeared in version 4, but don't quote me on that.
		// Also Note: Different Unreal Engines have different scales. Source: https://wiki.beyondunreal.com/Unreal_Unit
		//            It roughly translates to 1 uu(UT) = 1.125 uu(UT2k4) ~(The_Cowboy)
		// Level.Game.Broadcast(none, "Inside Cover/Seal: KillerPRI"@KillerPRI@"Flag Carrier"@FCs[KillerPRI.Team.TeamIndex]); For debug purpose :)
		if((VSize(Killed.Location - FCs[KillerPRI.Team.TeamIndex].Pawn.Location) < 512*1.125)
		|| (VSize(Killer.Pawn.Location - FCs[KillerPRI.Team.TeamIndex].Pawn.Location) < 512*1.125)
		|| (VSize(Killed.Location - FCs[KillerPRI.Team.TeamIndex].Pawn.Location) < 1536*1.125 && Killed.Controller.CanSee(FCs[KillerPRI.Team.TeamIndex].Pawn))
		|| (VSize(Killed.Location - FCs[KillerPRI.Team.TeamIndex].Pawn.Location) < 1024*1.125 && Killer.CanSee(FCs[KillerPRI.Team.TeamIndex].Pawn))
		|| (VSize(Killed.Location - FCs[KillerPRI.Team.TeamIndex].Pawn.Location) < 768*1.125 && Killed.Controller.LineOfSightTo(FCs[KillerPRI.Team.TeamIndex].Pawn))){
		// Killer DEFENDED THE Flag CARRIER
			if(!KillerInfo.bNull)
			{
				KillerInfo.Covers++;
				KillerInfo.CoverSpree++;// Increment Cover spree
				/*if(KillerInfo.CoverSpree == 3)
				{// Cover x 3
					BroadcastLocalizedMessage(class'SmartCTFMoreMessages', 2, KillerPRI);
				}
				else if(KillerStats.CoverSpree == 4)
				{// Cover x 4
					BroadcastLocalizedMessage(class'SmartCTFMoreMessages', 1, KillerPRI);
				}
				else
				{// Cover
					BroadcastLocalizedMessage(class'SmartCTFMoreMessages', 0, KillerPRI);
				}*/
			}
			KillerPRI.Score += CoverReward;// Cover Bonus
			Killer.AwardAdrenaline(CoverAdrenalineUnits);
			Log("Cover detected", 'Equalizer');
		}
		
		// Defense Kill
		bKilledTeamHasFlag = true;
		if(FCs[KilledPRI.Team.TeamIndex] == none) bKilledTeamHasFlag = false;
		if(FCs[KilledPRI.Team.TeamIndex] != none &&
		 FCs[KilledPRI.Team.TeamIndex].PlayerReplicationInfo.HasFlag == none) bKilledTeamHasFlag = false;// Safety check
		
		// if Killed's FC has not been set / if Killed's FC doesn't have our Flag
		/*if(!bKilledTeamHasFlag)
		{
			// If Killed and Killer's FC are in Killer's Flag Zone
			if(IsInZone(KilledPRI, KillerPRI.Team.TeamIndex) && IsInzone(FCs[KillerPRI.Team.TeamIndex].PlayerReplicationInfo, KillerPRI.Team.TeamIndex)){
				// Killer SEALED THE BASE
				if(KillerStats != none)
					KillerStats.Seals++;
				BroadcastLocalizedMessage(class'SmartCTFMoreMessages', 3, KillerPRI);
				KillerPRI.Score += SealAward;//Seal Bonus
				Killer.AwardAdrenaline(SealAdrenalineUnits);
			}
		}*/
	}
 }

/**
 * Method to return the EQPlayerInformation object.
 *
 * @param ID The ID of the player.
 * @return EQPlayers[i] The EQPlayerInformation oject associated to the ID
 *         None         If no EQPlayerInformation is associated.
 *
 * @since 0.1.0
 */

 function EQPlayerInformation GetInfoByID(int ID)
 {

	local int i;
	local EQPlayerInformation NullEQP;
	
	for(i = 0; i < EQPlayers.Length; i++)
	{
		if(EQPlayers[i].EQPlayerID == ID)
		{
			Log("Player found!", 'Equalizer');
			return EQPLayers[i];
		}
	}
	
	NullEQP.bNull = true;
	Log("Could not find the EQPlayerInformation of the ID: "$ID);
	return NullEQP;
 }

 defaultproperties
 {
    Version="0.1.0"
    BuildNumber=14
    Description="Equalizes and encourages CTF team gameplay."
    FriendlyName="DivineIntervention"
    CoverReward=2
    CoverAdrenalineUnits=5
 }
