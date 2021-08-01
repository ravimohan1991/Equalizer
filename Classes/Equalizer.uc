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
 * towards CTF goals.
 *
 * @author The_Cowboy
 * @since 0.1.0
 */

class Equalizer extends Mutator config(Equalizer);

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

 /** Controller Array of CTF's Flag Carriers */
 var   Controller                                 FCs[2];

 /** Controller Array of FC killers (may do with single array, categorized for readability) */
 var   array<EQPlayerInformation>                 RedFCKillers; // Killers in Red who killed Blue FC
 var   array<EQPlayerInformation>                 BlueFCKillers;

 /** Flags instances */
 var   CTFFlag                                  EQFlags[2];

 /** Are flaglocations set? */
 var     bool                                     bEQFlagsSet;

 /** Equalizer's silent spectator */
 var   MessagingSpectator                         Witness;

 /** Equalizer's UniqueIdentifier reference */
 var   Actor                                      EQUniqueIdentifier;

 /** if HTTP actor is active. */
 var bool HttpClientInstanceStarted;

 /** The HTTP client instance. */
 var EQHTTPClient HttpClientInstance;

 /** Number of restarts.*/
 var int NumHTTPRestarts;


 /*
  * Configurable Variables
  */

 var()   config           bool         bActivated;
 var()   config           int          CoverReward;
 var()   config           int          CoverAdrenalineUnits;
 var()   config           int          SealAward;
 var()   config           int          SealAdrenalineUnits;
 var()   config           bool         bShowFCLocation;
 var()   config           float        FCProgressKillBonus;
 var()   config           string       UniqueIdentifierClass;

 /** The radius of the bubble around the flag for tracking seals */
 var()   config           float        SealDistance;

 /** Switch for broadcasting Monsterkill and above.*/
 var()   config           bool         bBroadcastMonsterKillsAndAbove;

 /** Hosts with the capability of resovling Nations.*/
 var()   config           string        QueryServerHost;

 /** File path on Hosts.*/
 var()   config           string        QueryServerFilePath;

 /** Port for query.*/
 var()   config           int           QueryServerPort;

 /** Limit for the timeout.*/
 var()   config           int           MaxTimeout;

 /** Query server resolved address.*/
 var()   config           string        ResolvedAddress;

/**
 * The function gets called just after game begins. So we set up the
 * environmnet for Equalizer to operate.
 *
 * @since 0.1.0
 */

 function PostBeginPlay()
 {
	local EQGameRules EQGRules;
	local class<Actor> UniqueID;

	Log("Equalizer (v"$Version$") Initialized!", 'Equalizer');
	SaveConfig();
	EQGRules = Level.Game.Spawn(class'EQGameRules'); // for accessing PreventDeath function
	EQGRules.EQMut = self;
	Level.Game.AddGameModifier(EQGRules);// register the GameRules Modifier
	RegisterBroadcastHandler();
	UniqueID = class<Actor>(DynamicLoadObject(UniqueIdentifierClass, class'Class'));
	if(UniqueID != none)
		Log("Successfully loaded UniqueIdentifier class", 'Equalizer');
	EQUniqueIdentifier = Spawn(UniqueID, self);
	if(EQUniqueIdentifier != none)
		Log("Successfully spawned UniqueIdentifier instance", 'Equalizer');
	if(bShowFCLocation)
		Level.Game.HUDType = string(class'EQHUDFCLocation');

	InitHTTPFunctions();

	super.PostBeginPlay();
 }

/**
 * HTTP setup to communicate with the webserver
 *
 * @since 0.2.0
 */

 function InitHTTPFunctions()
 {
	if(!HttpClientInstanceStarted)
	{
		HttpClientInstance = Spawn(class'EQHTTPClient');
		HttpClientInstance.EQMut = self;
		HttpClientInstanceStarted = true;
	}
 }

/**
 * Function to restart the HTTPClient instance upon faliure
 *
 * @since 0.2.0
 */

 function RestartHTTPClient()
 {
	HttpClientInstance.Destroy();
	HttpClientInstanceStarted = False;

	if(NumHTTPRestarts < 4)
	{
		Log("Too many HTTP errors in one session, HTTP client restarting.", 'Equalizer');

		InitHTTPFunctions();
		NumHTTPRestarts++;
	}
	else
	{
		Log("Too many HTTP client restarts in one session, HTTP functions disabled.", 'Equalizer');
	}
 }

/**
 * Experimental function to send data to webserver
 *
 * @param Something The string of information to be sent
 * @since 0.2.0
 */

 function string SendData(string Something)
 {
	if(HttpClientInstanceStarted)
		return HttpClientInstance.SendData(Something, HttpClientInstance.SubmitEQInfo);
	else
		return "!Disabled";
 }


/**
 * Here we store the reference to the CTFFlag instances.
 *
 * @since 0.1.0
 */

 function SetEQFlags()
 {
	local CTFFlag Flag;

	foreach AllActors(class'CTFFlag', Flag)
	{
		EQFlags[Flag.TeamNum] = Flag;
		bEQFlagsSet = true;
	}
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
				if(Cont != Witness)
				{
					PlayerJoin(Cont);
				}
				break;
			}
		}
		CurrID++;
	}
 }

/**
 * The function clears the EQPlayers array          <br />
 * In future, we will hook algorithm to send        <br />
 * the data to backend, here.
 *
 * @since 0.1.0
 */

 function NotifyLogout(Controller Exiting)
 {

	local int PlayerIndex;

	for(PlayerIndex = 0; PlayerIndex < EQPlayers.Length; PlayerIndex++)
	{
		if(EQPlayers[PlayerIndex].Owner == Exiting.PlayerReplicationInfo)
		{
			if(!Exiting.PlayerReplicationInfo.bIsSpectator && !Exiting.PlayerReplicationInfo.bOnlySpectator)
			{
            EQPlayers[PlayerIndex].UpdateScore();
            EQPlayers[PlayerIndex].PlayersLastPlayingMoment();
			EQPlayers[PlayerIndex].SetTimer(0.f, false);
			EQPlayers[PlayerIndex].Destroy();
            EQPlayers.Remove(PlayerIndex, 1);
            }
			break;
		}
	}

	super.NotifyLogout(Exiting);
 }

/**
 * The function for setting the EQBroadcastHandler at the begining of the
 * linked list of BroadcastHandlers.
 *
 * TODO: Make the first handler in the list?
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
	local PlayerReplicationInfo EQPRI;

	if(!bEQFlagsSet)
	{
		SetEQFlags();
	}

	if(Witness == none)
	{
		Witness = Level.Game.Spawn(class'UTServerAdminSpectator');
		if(Witness != none)
		{
			Log("Successfully Spawned the Witness"@Witness, 'Equalizer');
			Witness.PlayerReplicationInfo.PlayerName = "Witness";
		}
		else
			Log("ERROR! Couldn't Spawn the Witness", 'Equalizer');
	}

	if(AIController(Other.Controller) != none)
	{
		BotController = Other.Controller;
		for(i = 0; i < EQPlayers.Length; i++)
		{
			EQPRI = PlayerReplicationInfo(EQPlayers[i].Owner);
			if(EQPRI != none && EQPRI.PlayerID == BotController.PlayerReplicationInfo.PlayerID)
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
 * Furthermore, it allows us to associate the uniqueidentifier with the player.
 *
 * @since 0.1.0
 */

 function PlayerJoin(Controller FreshMeat)
 {
	local EQPlayerInformation EQPI;

	if(FreshMeat.PlayerReplicationInfo == none || (FreshMeat.PlayerReplicationInfo.bIsSpectator && !FreshMeat.PlayerReplicationInfo.bWaitingPlayer))
		return;

	EQPI = Spawn(class'EQPlayerInformation', FreshMeat.PlayerReplicationInfo);
	EQPI.SetUniqueIdentifierReference(EQUniqueIdentifier);

	EQPlayers[EQPlayers.Length]	= EQPI;
 }

/**
 * Method to evaluate Covers, Seals and all that.
 *
 * @param Killed The Pawn class getting screwed.
 * @param Killer The Controller class screwing around.
 * @param damageType The nature of damage.
 * @param HitLocation The place of crime.
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

	if(KilledInfo != none)
	{
		KilledInfo.FragSpree = 0;// Reset FragSpree for Victim
		KilledInfo.CoverSpree = 0;
		KilledInfo.SpawnKillSpree = 0;
	}

	if(Killer == none || Killer == Killed.Controller)
	{
		if(KilledInfo != none)
		{
			KilledInfo.Suicides++;
			//KilledInfo.UpdateScore();
		}
		return;
	}

	KillerPRI = Killer.PlayerReplicationInfo;
	if(KillerPRI == none || (KillerPRI.bIsSpectator && !KillerPRI.bWaitingPlayer)) return;

	KillerInfo = GetInfoByID(Killer.PlayerReplicationInfo.PlayerID);

	if(KilledPRI.Team == KillerPRI.Team)
	{
		if(KillerInfo != none) KillerInfo.TeamKills++;
		return;
	}

	// Increase Frags and FragSpree for Killer
	if(KillerInfo != none)
	{
		KillerInfo.Frags++;
		KillerInfo.FragSpree++;
		if(KilledPRI.HasFlag != None)
		{
			KillerInfo.FlagKills++;
			KillerInfo.KilledFCAtLocation = Killed.Location;
			if(KillerPRI.Team.TeamIndex == 0)
			{
				AddIfNotPresent(0, KillerInfo);
			}
			else
			{
				AddIfNotPresent(1, KillerInfo);
			}
		}

		// HeadShot tracking
		if(damageType == Class'UTClassic.DamTypeClassicHeadshot')
		{
			KillerInfo.HeadShots++;
		}
	}

	if(KillerPRI.HasFlag == none && FCs[KillerPRI.Team.TeamIndex] != none && FCs[KillerPRI.Team.TeamIndex].Pawn != none && FCs[KillerPRI.Team.TeamIndex].PlayerReplicationInfo != none && FCs[KillerPRI.Team.TeamIndex].PlayerReplicationInfo.HasFlag != none)
	{
		// SEAL BASE

		// Defense Kill
		bKilledTeamHasFlag = true;
		if(FCs[KilledPRI.Team.TeamIndex] == none) bKilledTeamHasFlag = false;

		// if Killed's FC has not been set
		if(!bKilledTeamHasFlag)
		{
			// If Killed and Killer's FC are in Killer's Flag Zone
			if(IsInZone(Killed.Location, KillerPRI.Team.TeamIndex) && IsInzone(FCs[KillerPRI.Team.TeamIndex].Pawn.Location, KillerPRI.Team.TeamIndex))
			{
				// Killer SEALED THE BASE
				if(KillerInfo != none)
				{
					KillerInfo.Seals++;
				}
				BroadcastLocalizedMessage(class'EQMoreMessages', 3, KillerPRI);
				KillerPRI.Score += SealAward;//Seal Bonus
				Killer.AwardAdrenaline(SealAdrenalineUnits);
				return;
			}
		}

		// COVER FRAG
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
		if((VSize(Killed.Location - FCs[KillerPRI.Team.TeamIndex].Pawn.Location) < 512*1.125)
		|| (VSize(Killer.Pawn.Location - FCs[KillerPRI.Team.TeamIndex].Pawn.Location) < 512*1.125)
		|| (VSize(Killed.Location - FCs[KillerPRI.Team.TeamIndex].Pawn.Location) < 1536*1.125 && Killed.Controller.CanSee(FCs[KillerPRI.Team.TeamIndex].Pawn))
		|| (VSize(Killed.Location - FCs[KillerPRI.Team.TeamIndex].Pawn.Location) < 1024*1.125 && Killer.CanSee(FCs[KillerPRI.Team.TeamIndex].Pawn))
		|| (VSize(Killed.Location - FCs[KillerPRI.Team.TeamIndex].Pawn.Location) < 768*1.125 && Killed.Controller.LineOfSightTo(FCs[KillerPRI.Team.TeamIndex].Pawn)))
		{
			// Killer DEFENDED THE Flag CARRIER
			if(KillerInfo != none)
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
		}
	}
 }

/**
 * Here we update the player scores in EQPlayerInformation
 *
 * @param Killer The controller class who is to be rewarded
 * @since 0.2.0
 */

 function UpdateEQKillerScore(Controller Killer)
 {
	local EQPlayerInformation KillerInfo;

	if(Killer != none && Killer.PlayerReplicationInfo != none)
	{
		KillerInfo = GetInfoByID(Killer.PlayerReplicationInfo.PlayerID);
		if(KillerInfo != none)
		{
			KillerInfo.UpdateScore();
		}
	}
 }

/**
 * Adds the item in array if it does not exist
 *
 * @param TeamIndex The team of FCKillers
 * @param Info    The new information
 * @since 0.2.0
 */

 function AddIfNotPresent(int TeamIndex, EQPlayerInformation Info)
 {
	local int i;

	if(TeamIndex == 0)
	{
		for(i = 0; i < RedFCKillers.Length; i++)
		{
			if(RedFCKillers[i] == Info)
				return;
		}
		RedFCKillers[RedFCKillers.Length] = Info;
	}
	else
	{
		for(i = 0; i < BlueFCKillers.Length; i++)
		{
			if(BlueFCKillers[i] == Info)
				return;
		}
		BlueFCKillers[BlueFCKillers.Length] = Info;
	}
 }

/**
 * Method to intercept the broadcasted messages which contain important clues
 * about the Flag and FlagCarriers and Ingame events. We spawned the
 * UTServerAdminSpectator class instance as the Witness to interpret message only Once.
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

 function EvaluateMessageEvent(Actor Sender, PlayerController Receiver, class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
 {

	local CTFFlag Flag;
	local int FlagIndex;
	local EQPlayerInformation ReceiverInfo, SpectatorJoinInfo;

	if(MessagingSpectator(Receiver) != Witness) return;// No use going further.

	// First Blood register
	if(Message == class'FirstBloodMessage')
	{
		ReceiverInfo = GetInfoByID(RelatedPRI_1.PlayerID);
		if(ReceiverInfo != none) ReceiverInfo.bFirstBlood = true;
	}

	if(Message == Level.Game.GameMessageClass)
	{
		switch(Switch)
		{
			case 14:
					if(RelatedPRI_1 != none)
					{
						SpectatorJoinInfo = GetInfoByID(RelatedPRI_1.PlayerID);
						if(SpectatorJoinInfo != none)
						{
							PlayerBecameSpectator(SpectatorJoinInfo);
						}
					}
				break;
			case 1:// @see #PlayerController.BecomeActivePlayer()
					if(RelatedPRI_1 != none)
					{
						SpectatorJoinInfo = GetInfoByID(RelatedPRI_1.PlayerID);
						if(SpectatorJoinInfo != none)
						{
							SpectatorBecamePlayer(SpectatorJoinInfo);
						}
					}
				break;
		}
	}

	if(bBroadcastMonsterKillsAndAbove && Message == class'xDeathMessage')
	{
		if(RelatedPRI_1 == none || RelatedPRI_1.Owner == none || UnrealPlayer(RelatedPRI_1.Owner) == none) return;
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

	if(Message == class'CTFMessage')
	{
		if(Sender.IsA('CTFGame'))
		{
			for(FlagIndex = 0; FlagIndex < 2; FlagIndex++)
			{
				if(EQFlags[FlagIndex].Team == UnrealTeamInfo(OptionalObject))
				{
					Flag = EQFlags[FlagIndex];
					break;
				}
			}
		}
		else
			if(Sender.IsA('CTFFlag')) Flag = CTFFlag(Sender);
		else
			return;

		if(Flag == None)
			return;

		switch(Switch)
		{
			// CAPTURE
			// Sender: CTFGame, PRI: Scorer.PlayerReplicationInfo, OptObj: TheFlag.Team
			case 0:
					ReceiverInfo = GetInfoByID(RelatedPRI_1.PlayerID);
					if(ReceiverInfo != none)
					{
						ReceiverInfo.Captures++;
						ReceiverInfo.UpdateScore();
					}
					ResetSprees(0);
					ResetSprees(1);
					FCs[0] = none;
					FCs[1] = none;
				break;

			// DROP
			// Sender: CTFFlag, PRI: OldHolder.PlayerReplicationInfo, OptObj: TheFlag.Team
			case 2:
					//FCs[1-Flag.TeamNum] = none;// Just to be safe
				break;

			// PICKUP (after the FC dropped it)
			// Sender: CTFFlag, PRI: Holder.PlayerReplicationInfo, OptObj: TheFlag.Team
			case 4:
					FCs[1-Flag.TeamNum] = Controller(RelatedPRI_1.Owner);
				break;

			// GRAB (from the base mount-point)
			// Sender: CTFFlag, PRI: Holder.PlayerReplicationInfo, OptObj: TheFlag.Team
			case 6:
					FCs[1-Flag.TeamNum] = Controller(RelatedPRI_1.Owner);
					ReceiverInfo = GetInfoByID(FCs[1-Flag.TeamNum].PlayerReplicationInfo.PlayerID);
					if(ReceiverInfo != none) ReceiverInfo.Grabs++;
				break;

			// RETURN
			//  Sender: CTFGame, PRI: Scorer.PlayerReplicationInfo, OptObj: TheFlag.Team
			case 1:
					if(RelatedPRI_1 != none)
					{
						RewardFCKillers(RelatedPRI_1.Team.TeamIndex);
					}

			// Sender: CTFFlag, PRI: Holder.PlayerReplicationInfo, OptObj: TheFlag.Team
			case 3:
			case 5:
					FCs[1-Flag.TeamNum] = none;
					ResetSprees(1 - Flag.TeamNum);
					ResetFCKillers(Flag.TeamNum);
				break;
		}
	}
 }

 /**
 * Here we do the necessary arrangements when a player becomes
 * a spectator
 *
 * @param SpectatorJoinInfo The EQPlayerInfo of the player who became spectator
 * @since 0.2.0
 */

 function PlayerBecameSpectator(EQPlayerInformation SpectatorJoinInfo)
 {
	SpectatorJoinInfo.PlayerBecameSpectator();
    // Maybe send the information to the backend
 }

 /**
 * Here we do the necessary arrangements when a spectator
 * becomes player
 *
 * @param SpectatorJoinInfo The EQPlayerInfo of the spectator who became player
 * @since 0.2.0
 */

 function SpectatorBecamePlayer(EQPlayerInformation SpectatorJoinInfo)
 {
	SpectatorJoinInfo.SpectatorBecamePlayer();
 }

/**
 * Method to reset sprees
 *
 * @param TeamIndex The team of player's whose sprees are to be reset
 * @since 0.1.0
 */

 function ResetSprees(int TeamIndex)
 {
	local int i;
	local PlayerReplicationInfo EQPRI;

	for(i = 0; i < EQPlayers.Length; i++)
	{
		EQPRI = PlayerReplicationInfo(EQPlayers[i].Owner);
		if(EQPRI != none && EQPRI.Team != none && EQPRI.Team.TeamIndex == TeamIndex)
		{
			EQPlayers[i].CoverSpree = 0;
		}
	}
 }

/**
 * Method to reward FCKillers
 *
 * @param TeamIndex The team index of Flag, which has FCKillers
 * @since 0.2.0
 */

 function RewardFCKillers(int TeamIndex)
 {
	local int i;
	local PlayerReplicationInfo EQPRI;
	local vector KillerBaseToFCBaseVector;
	local vector KillerBaseToFCLocationVector;
	local float  FCProgress;
	local int ScoreToAward;

	if(TeamIndex == 0)
	{
		KillerBaseToFCBaseVector = EQFlags[1].HomeBase.Location - EQFlags[0].HomeBase.Location;
		for(i = 0; i < RedFCKillers.Length; i++)
		{
			EQPRI = PlayerReplicationInfo(RedFCKillers[i].Owner);
			if(EQPRI != none)
			{
				KillerBaseToFCLocationVector = RedFCKillers[i].KilledFCAtLocation - EQFlags[0].HomeBase.Location;
				FCProgress = KillerBaseToFCLocationVector dot Normal(KillerBaseToFCBaseVector);
				if(FCProgress > 0)
				{
					ScoreToAward = int(FClamp(FCProgress / VSize(KillerBaseToFCBaseVector), 0.f, 1.f) * FCProgressKillBonus);
					EQPRI.Score += ScoreToAward;
					RedFCKillers[i].UpdateScore();
				}
			}
		}
	}
	else
	{
		KillerBaseToFCBaseVector = EQFlags[0].HomeBase.Location - EQFlags[1].HomeBase.Location;
		for(i = 0; i < BlueFCKillers.Length; i++)
		{
			EQPRI = PlayerReplicationInfo(BlueFCKillers[i].Owner);
			if(EQPRI != none)
			{
				KillerBaseToFCLocationVector = BlueFCKillers[i].KilledFCAtLocation - EQFlags[1].HomeBase.Location;
				FCProgress = KillerBaseToFCLocationVector dot Normal(KillerBaseToFCBaseVector);
				if(FCProgress > 0)
				{
					ScoreToAward = int(FClamp(FCProgress / VSize(KillerBaseToFCBaseVector), 0.f, 1.f) * FCProgressKillBonus);
					EQPRI.Score += ScoreToAward;
					BlueFCKillers[i].UpdateScore();
				}
			}
		}
	}
 }

/**
 * Method to reset FCKillers
 *
 * @param TeamIndex The team index of Flag, which has FCKillers
 * @since 0.2.0
 */

 function ResetFCKillers(int TeamIndex)
 {
	if(TeamIndex == 0)
	{
		RedFCKillers.Remove(0, RedFCKillers.Length);
	}
	else
	{
		BlueFCKillers.Remove(0, BlueFCKillers.Length);
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
	local PlayerReplicationInfo EQPRI;

	for(i = 0; i < EQPlayers.Length; i++)
	{
		EQPRI = PlayerReplicationInfo(EQPlayers[i].Owner);
		if(EQPRI != none && EQPRI.PlayerID == ID)
		{
			return EQPLayers[i];
		}
	}

	return none;
 }

/**
 * Method to check if the Player is in Flag zone.
 *
 * @param PRI The PlayerReplicationInfo class of the Player.
 * @param Team The team of Flag
 *
 * @see #EvaluateKillingEvent(Killed, Killer, DamageType, Location)
 * @since 0.1.0
 */

 function bool IsInZone(vector SubjectLocation, byte Team)
 {

	if(VSize(SubjectLocation - EQFlags[Team].HomeBase.Location) < SealDistance)
		return true;

	return false;
 }

/**
 * For debugging purposes
 *
 * @param MutateString The string typed by the player
 * @param Sender Human how typed the command
 *
 * @since 0.1.0
 */


 function Mutate(string MutateString, PlayerController Sender)
 {
	local EQPlayerInformation EQPlayerInfo ;

    if(Sender != none)
	{

		// allset in backend only for addition of new records. Was trying to test that!
        EQPlayerInfo = GetInfoByID(Sender.PlayerReplicationInfo.PlayerID);
        if(EQPlayerInfo != none)
        {
           EQPlayerInfo.PlayersLastPlayingMoment();
           HttpClientInstance.SendData(EQPlayerInfo.GenerateArpanString(), HttpClientInstance.SubmitEQInfo);
           Sender.ClientMessage(EQPlayerInfo.GenerateArpanString());
        }




		//HttpClientInstance.SendData(MutateString, HttpClientInstance.SubmitEQInfo);
		/*
		if (MutateString ~= "dist")
		Sender.ClientMessage("Distance from red flag: "$VSize(Sender.Pawn.Location - EQFlags[0].HomeBase.Location)$" distance from blue flag: "$VSize(Sender.Pawn.Location - 				EQFlags[1].HomeBase.Location));
		*/
	}

	if ( NextMutator != None )
		NextMutator.Mutate(MutateString, Sender);
 }

 defaultproperties
 {
    Version="0.2.0"
    BuildNumber=63
    Description="Equalizes and encourages CTF team gameplay."
    FriendlyName="DivineIntervention"
    CoverReward=2
    CoverAdrenalineUnits=5
    SealAward=2
    SealAdrenalineUnits=5
    bBroadcastMonsterKillsAndAbove=true
    bShowFCLocation=true
    SealDistance=2200
    FCProgressKillBonus=4
    UniqueIdentifierClass="UniqueIdentifier.UniqueIdentifier"
    QueryServerHost="192.168.1.2"
    QueryServerFilePath="/EqualizerBE/eqquery.php"
    QueryServerPort=80
    MaxTimeout=10
 }
