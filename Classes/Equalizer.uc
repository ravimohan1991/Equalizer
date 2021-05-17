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
 * Equalizer is a Mutator which makes sure that the CTF matches are		<br />
 * played between teams of equal calibre. It will further acknowledge and	<br />
 * encourage the team gameplay leading to a justly competitive match.		<br />
 * The aim is to gauge the match awareness, reactivity and commitment		<br />
 * towards CTF goals.		<br />
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
 	var    PlayerReplicationInfo             EQPRI;

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

 /** Equalizer's silent spectator.*/
 var   MessagingSpectator                         Witness;

 /*
  * Configurable Variables
  */

 var()   config           bool         bActivated;
 var()   config           int          CoverReward;
 var()   config           int          CoverAdrenalineUnits;

 /** Switch for broadcasting Monsterkill and above.*/
 var()   config           bool         bBroadcastMonsterKillsAndAbove;

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
	RegisterBroadcastHandler();
	Witness = Level.Game.Spawn(class'UTServerAdminSpectator');
     if(Witness != none)
     {
        Log("Successfully Spawned the Witness"@Witness, 'Equalizer');
        Witness.PlayerReplicationInfo.PlayerName = "Witness";
     }
     else
        Log("ERROR! Couldn't Spawn the Witness", 'Equalizer');

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
 * The function for setting the EQBroadcastHandler at the begining of the
 * linked list of BroadcastHandlers.
 *
 * @since 0.1.0
 */

 function RegisterBroadcastHandler()
 {

    local EQBroadcastHandler EQBH;

    EQBH = Level.Game.Spawn(class'EQBroadcastHandler');
    EQBH.EQMut = self;

    Level.Game.BroadcastHandler.RegisterBroadcastHandler(EQBH);
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
			if(EQPlayers[i].EQPRI.PlayerID == BotController.PlayerReplicationInfo.PlayerID)
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

	EQPI.EQPRI                = FreshMeat.PlayerReplicationInfo;
	EQPlayers[EQPlayers.Length] = EQPI;

	Log("Started tracking player "$EQPI.EQPRI.PlayerName, 'Equalizer');
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

		Log(KillerInfo.EQPRI.PlayerName$" has total frags = "$KillerInfo.Frags);
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
		|| (VSize(Killed.Location - FCs[KillerPRI.Team.TeamIndex].Pawn.Location) < 768*1.125 && Killed.Controller.LineOfSightTo(FCs[KillerPRI.Team.TeamIndex].Pawn)))
        {
		    // Killer DEFENDED THE Flag CARRIER
			if(!KillerInfo.bNull)
			{
				KillerInfo.Covers++;
				KillerInfo.CoverSpree++;// Increment Cover spree
				if(KillerInfo.CoverSpree < 3)
				{// Cover
					BroadcastLocalizedMessage(class'EQMoreMessages', 0, KillerPRI);
				}
				else if(KillerInfo.CoverSpree == 3)
				{// Cover x 3
					BroadcastLocalizedMessage(class'EQMoreMessages', 1, KillerPRI);
				}
				else
				{// Good Job!
					BroadcastLocalizedMessage(class'EQMoreMessages', 2, KillerPRI);
				}
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
 * Method to intercept the broadcasted messages which contain important clues
 * about the Flag and FlagCarriers and Ingame events. We spawned the
 * UTServerAdminSpectator Class instance as the Witness to interpret message only Once.
 *
 * @param Sender The Actor class sending the message.
 * @param Receiver The Controller class receiving the message.
 * @param Message The real message.
 * @param switch Category of Message.
 * @param Related_PRI1 Involved PlayerReplicationInfo 1
 * @param Related_PRI2 Involved PlayerReplicationInfo 2
 * @param OptionalObject Involved Object (Could be a Flag)
 *
 * @see #UnrealGame.CTFMessage
 * @since 0.1.0
 * authors of this routine can be found at http://wiki.unrealadmin.org/SmartCTF
 */

 function EvaluateMessageEvent(Actor Sender, PlayerController Receiver, class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject){

    local CTFFlag Flag;
    local EQPlayerInformation ReceiverInfo;

    // First Blood register
    if(Message == class'FirstBloodMessage')
    {
       if(UTServerAdminSpectator(Receiver) == none) return;
       if(MessagingSpectator(Receiver) == Witness)
       {
          ReceiverInfo = GetInfoByID(RelatedPRI_1.PlayerID);
          if(!ReceiverInfo.bNull) ReceiverInfo.bFirstBlood = true;
       }
    }

    // "Became a Spectator" fix!
    if(Message == Level.Game.GameMessageClass){
       switch(Switch)
       {
          case 14:
             RelatedPRI_1.bIsSpectator = true;
             break;
       }
    }

    if(bBroadcastMonsterKillsAndAbove && Message == class'xDeathMessage')
    {
       if(UTServerAdminSpectator(Receiver) == none || RelatedPRI_1 == none || RelatedPRI_1.Owner == none || UnrealPlayer(RelatedPRI_1.Owner) == none) return;
       if(MessagingSpectator(Receiver) == Witness)
       {
          switch(UnrealPlayer(RelatedPRI_1.Owner).MultiKillLevel)
          {
             case 5:
             case 6:
             case 7:
                Level.Game.Broadcast(none, RelatedPRI_1.PlayerName@"had a"@
                class'MultiKillMessage'.default.KillString[Min(UnrealPlayer(RelatedPRI_1.Owner).MultiKillLevel,7)-1]);
                break;
          }
       }
    }

    if(Message == class'CTFMessage')
    {
       if(Sender.IsA('CTFGame'))
       {
          foreach DynamicActors(class'CTFFlag', Flag)
             if(Flag.Team == UnrealTeamInfo(OptionalObject))
                break;
       }
       else
          if(Sender.IsA('CTFFlag')) Flag = CTFFlag(Sender);
       else
          return;
       if(Flag == None)
          return;
       if(UTServerAdminSpectator(Receiver) == none) return;// No use going further.
       switch(Switch)
       {
          // CAPTURE
          // Sender: CTFGame, PRI: Scorer.PlayerReplicationInfo, OptObj: TheFlag.Team
          case 0:
             if(MessagingSpectator(Receiver) == Witness)
             {//Controller(RelatedPRI_1.Owner)){
                ReceiverInfo = GetInfoByID(RelatedPRI_1.PlayerID);
                if(!ReceiverInfo.bNull) ReceiverInfo.Captures++;
                ResetSprees(0);
                ResetSprees(1);
                FCs[0] = none;
                FCs[1] = none;
             }
             break;

          // DROP
          // Sender: CTFFlag, PRI: OldHolder.PlayerReplicationInfo, OptObj: TheFlag.Team
          case 2:
             FCs[1-Flag.TeamNum] = none;// Just to be safe
             break;

          // PICKUP (after the FC dropped it)
          // Sender: CTFFlag, PRI: Holder.PlayerReplicationInfo, OptObj: TheFlag.Team
          case 4:
             if(MessagingSpectator(Receiver) == Witness)
             {
                FCs[1-Flag.TeamNum] = Controller(RelatedPRI_1.Owner);
             }
             break;

          // GRAB (from the base mount-point)
          // Sender: CTFFlag, PRI: Holder.PlayerReplicationInfo, OptObj: TheFlag.Team
          case 6:
             if(MessagingSpectator(Receiver) == Witness)
             {// Receiver == FirstHuman
                FCs[1-Flag.TeamNum] = Controller(RelatedPRI_1.Owner);
                ReceiverInfo = GetInfoByID(FCs[1-Flag.TeamNum].PlayerReplicationInfo.PlayerID);
                if(!ReceiverInfo.bNull) ReceiverInfo.Grabs++;
             }
             break;

          // RETURN
          case 1:
          case 3:
          case 5:
             if(MessagingSpectator(Receiver) == Witness)
                ResetSprees(Flag.TeamNum);
                //return;
             break;
       }
     }
 }

/**
 * Method to reset sprees
 *
 * @param Team The team of players whose sprees are to be reset
 * @since 0.1.0
 */

 function ResetSprees(int Team)
 {


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
		if(EQPlayers[i].EQPRI.PlayerID == ID)
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
    bBroadcastMonsterKillsAndAbove=True
 }
