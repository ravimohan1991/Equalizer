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
 * The aim is to gauge the match awareness, reactivity, and commitment		<br />
 * towards CTF goals.
 *
 * @author The_Cowboy
 * @since 0.1.0
 */

class Equalizer extends Mutator config(Equalizer_TC_alpha1);

/*
 * Global Variables
 */

 /** String with Version of the Mutator. */
 var   string                                     Version;

 /** Number of times Equalizer has been built. */
 var   float                                      BuildNumber;

 /** For tracking the PlayerJoin. */
 var   int                                        CurrID;

 /** Equalizer PlayerInformation array. */
 var   array<EQPlayerInformation>                 EQPlayers;

 /** Controllers whose PRI hasn't been spawned at PlayerJoin. */
 var   array<Controller>                          ToBePRIs;

 /** Controller Array of CTF's Flag Carriers. */
 var   Controller                                 FCs[2];

 /** Controller Array of FC killers (may do with single array, categorized for readability). */
 var   array<EQPlayerInformation>                 RedFCKillers; // Killers in Red who killed Blue FC
 var   array<EQPlayerInformation>                 BlueFCKillers;

 /** Flags instances. Helpful for identifying zones and other useful properties. */
 var   CTFFlag                                  EQFlags[2];

 /** Are flaglocations set? */
 var     bool                                     bEQFlagsSet;

 /** Equalizer's silent spectator! */
 var   MessagingSpectator                         Witness;

 /** Equalizer's UniqueIdentifier reference. */
 var   UniqueIdentifier                           EQUniqueIdentifier;

 /** Is HTTP actor active? */
 var bool HttpClientInstanceStarted;

 /** The HTTP client instance. */
 var EQHTTPClient HttpClientInstance;

 /** Number of restarts. Should leave after how many attempts? */
 var int NumHTTPRestarts;

 /** The GameInfo reference. */
 var CTFGame CTFGameInfo;

 /** The Scoreboard in the form of Sorter. */
 // This might affect the order of ServerActors loading.
 // Not being used currently though. For legacy purposes I think!
 var Scoreboard PlayerSorter;

 /** The global reference to Game rules. */
 var EQGameRules EQGRules;

 /** Global Arzi string (for clustering scheme!). */
 var string GArziString;

 /** Balancing switch. */
 var bool bWannaBalance;


 //piglet : GLobal things related to balancing
 var bool BMatchAboutToStartDone;
 var byte myStartupStage;
 var TeamSizeBalancer MyTeamSizeBalancer;

 var FileLog MyLogfile;


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
 var()   config           string       TeamSizeBalancerClass;


 //Balancing options
 var     config           bool         bBalanceAtMapStart;
 var     config           bool         bMidGameMonitoring;
 var     config           byte         BalanceMethod;
 var     config           int          MinimumTimePlayed;   ///ignore players with this amount of minutes or fewer

 //Debug options
 var     config           bool         bDebugIt;

 /** The radius of the bubble around the flag for tracking seals. */
 var()   config           float        SealDistance;

 /** Switch for broadcasting Monsterkill and above. */
 var()   config           bool         bBroadcastMonsterKillsAndAbove;

 /** Host with the capability of resovling Nations. */
 var()   config           string        QueryServerHost;

 /** File path on Host. */
 var()   config           string        QueryServerFilePath;

 /** Port for query. */
 var()   config           int           QueryServerPort;

 /** Limit for the timeout. */
 var()   config           int           MaxTimeout;

 /** Query server resolved address. */
 var()   config           string        ResolvedAddress;

 /** Following variables are for MegaTesting scenarios. Only for Admin. */

 /** Should we display the teams before and after sorting, in the console? */
 var()   config            bool         bShowTeamsRollCall;

 /** Log the teams before and after sorting? */
 var()   config            bool         bLogTeamsRollCall;

 /** Log label string. */
 var()   config            name         LogCompanionTag;

/**
 * The function gets called just after game begins. So we set up the
 * environmnet for Equalizer to operate.
 *
 * @since 0.1.0
 */

 // Set up timer to watch for ganme start countdown. Yes...there may be a better way, but this works for now.
 function PreBeginPlay()
 {
	if (bBalanceAtMapStart)
	{
		setTimer(0.1f, True);
		myStartupStage = -1;
	}
	else
	{
		BMatchAboutToStartDone = true;
	}
 }

 function PostBeginPlay()
 {
	local class<UniqueIdentifier> UniqueID;

	CTFGameInfo = CTFGame(Level.Game);
	if(CTFGameInfo == none)
	{
		Log("The GameType is not CTF. Why even bother running this mutator?!", LogCompanionTag);
		Destroyed();  //why not Destroy()?
		return;
	}

	EQGRules = Level.Game.Spawn(class'EQGameRules', self, 'EndGame'); // for accessing PreventDeath function
	EQGRules.EQMut = self;
	Level.Game.AddGameModifier(EQGRules);// register the GameRules Modifier
	RegisterBroadcastHandler();
	UniqueID = class<UniqueIdentifier>(DynamicLoadObject(UniqueIdentifierClass, class'Class'));
	if(UniqueID != none && bDebugIt)
		Log("Successfully loaded UniqueIdentifier class", LogCompanionTag);
	EQUniqueIdentifier = Spawn(UniqueID, self);
	if(EQUniqueIdentifier != none && bDebugIt)
		Log("Successfully spawned UniqueIdentifier instance", LogCompanionTag);
	if(bShowFCLocation)
		Level.Game.HUDType = string(class'EQHUDFCLocation');

	InitHTTPFunctions();

	// Fore safety!
	GArziString = "";
	bWannaBalance = false;

	Log("Equalizer_TC_alpha1 (v"$Version$") Initialized!", LogCompanionTag);
 }

/**
 * HTTP setup to communicate with the webserver.
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
 * Function to restart the HTTPClient instance upon faliure.
 *
 * @since 0.2.0
 */

 function RestartHTTPClient()
 {
	HttpClientInstance.Destroy();
	HttpClientInstanceStarted = False;

	if(NumHTTPRestarts < 4)
	{
		Log("Too many HTTP errors in one session, HTTP client restarting.", LogCompanionTag);

		InitHTTPFunctions();
		NumHTTPRestarts++;
	}
	else
	{
		Log("Too many HTTP client restarts in one session, HTTP functions disabled.", LogCompanionTag);
	}
 }

/**
 * Experimental function to send data to webserver.
 *
 * @param Something     The string of information to be sent
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
 *
 * @param DeltaTime     Amount of time elapsed between two consecutive ticks
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

	if(GArziString != "")
	{
		SendArziToBE();
	}
 }

/**
 * Here we write our special sauce, the function(s) that do(es) it all (I mean Equalize).
 *
 * @since 0.3.6
 * @see GatherAndProcessInformation
 */

 function FullBalanceCTFTeams(bool actuallybalance, bool bTellEveryone)
 {
	local int CacheMinPlayers;

	if(EQPlayers.Length == 0)
	{
		Log("There is nothing in the EQPlayers array. Balancing can't happen this way.", LogCompanionTag);
		return;
	}

	// We want to seperate bots and Humans
	// which is crucial for balancing during gameplay.
	// Before the match starts, there are no bots.

	if (actuallybalance)
	{
		// For bot-crowd seperation from Humans and filtering
		CacheMinPlayers = CTFGameInfo.MinPlayers;

		// Bots... don't interfare in Balancing!
		CTFGameInfo.MinPlayers = 0;
		CTFGameInfo.KillBots(Level.Game.NumBots);
	}


	//This sort and fill only works on a single parameter. Where there is a need for more complexity around ensuring equal distribution of cappers and defenders etc this area will need to be reassessed.
	SortEQPInfoArray(BalanceMethod);
	NuclearShellFillAlgorithm(actuallybalance, bTellEveryone);
	//end sort and fill

	// Restore the bot-crowd
	if (actuallybalance)
		CTFGameInfo.MinPlayers = CacheMinPlayers;
 }

/**
 * Piglet(UK) and my personal take on balancing CTF teams using alternating
 * distribution of sorted list of players (see function SortEQPInfoArray) in
 * Red and Blue categories.
 *
 * @since 0.3.6
 */

 function NuclearShellFillAlgorithm(bool actuallybalance, bool bTellEveryone)
 {
	local int index, playercount;
	local PlayerReplicationInfo LambPRI;
	local byte TeamToSwitchTo;

	TeamToSwitchTo = 0;// We start with Red team as per suggestion
	playercount = 0;// We start with Red team as per suggestion

	// Assuming EQPlayers array is "contiguous", meaning, no reference is null and order is descending
	for(index = 0; index < EQPlayers.Length; index++)
	{
		if(!EQPlayers[index].bDisturbInLineUp || EQPlayers[index].bIsBot)
		{
			continue;
		}

		LambPRI = PlayerReplicationInfo(EQPlayers[index].Owner);

		if(LambPRI == none)
		{
			continue;
		}

		if (!actuallybalance){
			piglogwrite(index@"I would have balanced to team"@TeamToSwitchTo@LambPRI.PlayerName $ " : " $ EQPlayers[index].BPValue(BalanceMethod));
		}


		if(LambPRI.Team.TeamIndex != TeamToSwitchTo)
		{
			EQGRules.ChangeTeam(PlayerController(LambPRI.Owner), TeamToSwitchTo);
		}
		else{
			if (bTellEveryone)
				Level.Game.BroadcastHandler.BroadcastLocalized(none, PlayerController(LambPRI.Owner), class'EQTeamSwitchMessage', TeamToSwitchTo, PlayerController(LambPRI.Owner).PlayerReplicationInfo);
		}

		// Alternating team population procedure

		//First player to red, next two to blue, then alternate
		if (++playercount != 2)
			TeamToSwitchTo = 1 - TeamToSwitchTo;

		//piglet lets leave everyone available for now.
		//EQPlayers[index].bDisturbInLineUp = false;
	}
 }

/**
 * Simple selection sort based on desired parameter.
 *
 * @param BalanceMethod     An Integer based on the declaration done in EQPlayerInformation::BPValue
 * @since 0.3.6
 */

 function SortEQPInfoArray(int BalanceMethod)
 {
	local int i, j;
	local EQPlayerInformation tmp;

	for (i = 0; i < EQPlayers.Length-1; i++)
	{
		for (j = i+1; j < EQPlayers.Length; j++)
		{
			if(!InOrder(EQPlayers[i], EQPlayers[j], BalanceMethod))
			{
				tmp = EQPlayers[i];
				EQPlayers[i] = EQPlayers[j];
				EQPlayers[j] = tmp;
			}
		}
	}
 }

/**
 * A check with enough complexity to gauge the order of EQPlayerInformation instances
 * and facilitate the array sorting based on some parameter.
 * Once the metric is defined this way, sorting is done in descending order.
 *
 * @param EQP1, EQP2     The EQPlayerInformation instances of the Humans (and Bots?) which need comparison
 * @param BalanceMethod An Integer based on the declaration done in EQPlayerInformation::BPValue
 * @since 0.3.6
 */

 function bool InOrder(EQPlayerInformation EQP1, EQPlayerInformation EQP2, int BalanceMethod)
 {
	local PlayerReplicationInfo P1, P2;

	P1 = PlayerReplicationInfo(EQP1.Owner);
	P2 = PlayerReplicationInfo(EQP2.Owner);

	// Safety check!
	if(P1 == none)
	{
		if (bDebugIt)
			Log("The OwnerPlayerReplicationInfo of Player with ID: " $ EQP1.EQIdentifier $ " does not exist! Normal order can't be determined. Trying Contextual Ordering.", LogCompanionTag);
		if(P2 == none)
		{
			if (bDebugIt)
				Log("Ok we can't really do anything now because both Owners are none. Even contextual ordering is rendered useless!", LogCompanionTag);
			return true;// Note this "true" is not the same "true" we gauge then we are satisfied with the order.  This true means order can't be determined and we are dealing with degeneracy.
				    // Seems computationally it is no different from order satisfaction?
		}
		else
		{
			return false;
		}
	}
	else if(P2 == none)
	{
		if (bDebugIt)
			Log("The OwnerPlayerReplicationInfo of Player with ID: " $ EQP2.EQIdentifier $ " does not exist! Normal order can't be determined. Trying Contextual Ordering.", LogCompanionTag);
		return true;
	}

	if(P1.bOnlySpectator)
	{
		if(P2.bOnlySpectator)
			return true;
		else
			return false;
	}
	else if (P2.bOnlySpectator)
		return true;

	if(EQP1.bIsBEReady)
	{
		if(!EQP2.bIsBEReady)
		{
			return true;
		}
	}
	else if(EQP2.bIsBEReady)
	{
		return false;
	}

	if(EQP1.BPValue(BalanceMethod) <  EQP2.BPValue(BalanceMethod))
		return false;

	return true;
 }

/**
 * Here we generate an "arzi" string with relevant clustering scheme (need to define it, although clear from code!).
 *
 * @param EQPlayerInfo    The EQPlayerInformation of the player whose backed data needs updating
 * @since 0.3.6
 */

 function GenerateGAString(EQPlayerInformation EQPlayerInfo)
 {
	Log("GenerateGAString: " $ EQPlayerInfo.EQIdentifier , LogCompanionTag);

 	if(GArziString != "")
 	{
 		GArziString = GArziString $ "," $ EQPlayerInfo.EQIdentifier;
 	}
 	else
 	{
 		GArziString = EQPlayerInfo.EQIdentifier;
 	}
 }

/**
 * Send the arzi to backend.
 *
 * @since 0.3.6
 */

 function SendArziToBE()
 {
	if (bDebugIt)
		Log("Global Arzi string is: " $ GArziString, LogCompanionTag);
 	HttpClientInstance.SendData(GArziString, HttpClientInstance.QueryEQInfo);
 	GArziString = "";
 }

/**
 * The function clears the EQPlayers array
 * In future, we will hook algorithm to send
 * the data to backend, here. And we did now!
 *
 * Clustering scheme for arpan too?!
 *
 * @param Exiting     The Controller instance of player exiting the Game
 * @since 0.1.0
 */

 function NotifyLogout(Controller Exiting)
 {
	local int PlayerIndex;

	if(EQPlayers.Length == 0)
	{
		return;
	}

	for(PlayerIndex = 0; PlayerIndex < EQPlayers.Length; PlayerIndex++)
	{
		if(EQPlayers[PlayerIndex].Owner == Exiting.PlayerReplicationInfo)
		{
			if(!Exiting.PlayerReplicationInfo.bIsSpectator && !Exiting.PlayerReplicationInfo.bOnlySpectator)
			{
				if (bDebugIt)
					Log("Player: " $ Exiting.PlayerReplicationInfo.PlayerName $ " logging out.", LogCompanionTag);
				SendEQDataToBackEnd(EQPlayers[PlayerIndex]);
				EQPlayers[PlayerIndex].SetTimer(0.0f, false);
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
 * The function to spawn the Witness and check if Flag Actors are set.
 *
 * @param Other     The Pawn instance of humanplayer or bot
 * @since 0.1.0
 */

 function ModifyPlayer(Pawn Other)
 {
	if(!bEQFlagsSet)
	{
		SetEQFlags();
	}

	if(Witness == none)
	{
		Witness = Level.Game.Spawn(class'UTServerAdminSpectator');
		if(Witness != none)
		{
			if (bDebugIt)
				Log("Successfully Spawned the Witness"@Witness, LogCompanionTag);
			Witness.PlayerReplicationInfo.PlayerName = "Witness";
		}
		else
			Log("ERROR! Couldn't Spawn the Witness", LogCompanionTag);
	}

	if(NextMutator != None)
		NextMutator.ModifyPlayer(Other);
 }

/**
 * Here, we add the Equalizer marker to the player.
 * It will facilitate the tracking of player stats.
 * Furthermore, it allows us to associate the uniqueidentifier with the player.
 *
 * @param FreshMeat     The Controller instance of new joinings
 * @since 0.1.0
 */

 function PlayerJoin(Controller FreshMeat)
 {
	if((FreshMeat.PlayerReplicationInfo.bIsSpectator && !FreshMeat.PlayerReplicationInfo.bWaitingPlayer))
		return;

	if(FreshMeat.PlayerReplicationInfo != none)
	{
		EQPlayers[EQPlayers.Length] = SpawnEQPlayerInfo(FreshMeat.PlayerReplicationInfo);
	}
	else
	{
		if (bDebugIt)
			Log("PlayerReplicationInfo is none and now waiting for the spawn.", LogCompanionTag);
		WaitingForPRIToSpawn(FreshMeat);
	}
 }

/**
 * Here we augment all the Controllers whose PRIs haven't spawned at the time of
 * PlayerJoin.
 *
 * @param Cont     The Controller instance of player for whom we wait to get the PRI instance spawned
 * @since 0.3.0
 */

 function WaitingForPRIToSpawn(Controller Cont)
 {
	ToBePRIs[ToBePRIs.Length] = Cont;

	if(TimerRate == 0.0f)
	{
		SetTimer(1.0f, true);
	}
 }

 /**
 * Spawn EQPlayerInformation routine and associate the PlayerReplicaitonInfo
 * as the Owner.
 *
 * @param TheOwner     The Actor assigned as owner of the EQPlayerInformation instance
 * @since 0.3.6
 */

 function EQPlayerInformation SpawnEQPlayerInfo(Actor TheOwner)
 {
	local EQPlayerInformation EQPI;

	EQPI = Spawn(class'EQPlayerInformation', TheOwner);
	EQPI.SetUniqueIdentifierReference(EQUniqueIdentifier);
	EQPI.MYMUT = self;

	bWannaBalance = true;

	return EQPI;
 }

/**
 * The Timer function which checks if the PRIs of the relevant Controllers are
 * existing and if yes then Spawns the corresponding EQPlayerInformation class.
 * Useful for Controllers with late spawning PRIs.
 *
 * @since 0.3.0
 */

 event Timer()
 {
	local byte ContIndex;

	if (myStartupStage != DeathMatch(level.game).startupStage){
			myStartupStage = DeathMatch(level.game).startupStage;
			if (myStartupStage == 3){
				MatchAboutToStart();
				if(ToBePRIs.Length == 0)
					SetTimer(0.0f, false);
			}
	}

	for(ContIndex = 0; ContIndex < ToBePRIs.Length; ContIndex++)
	{
		if(ToBePRIs[ContIndex].PlayerReplicationInfo != none)
		{
			EQPlayers[EQPlayers.Length]	= SpawnEQPlayerInfo(ToBePRIs[ContIndex].PlayerReplicationInfo);

			ToBePRIs.Remove(ContIndex, 1);

			if(ToBePRIs.Length == 0 && BMatchAboutToStartDone)
			{
				SetTimer(0.0f, false);
			}
		}
	}
 }

/**
 * Method to evaluate Covers, Seals and all that.
 *
 * @param Killed      The Pawn class getting screwed.
 * @param Killer      The Controller class screwing around.
 * @param damageType    The nature of damage.
 * @param HitLocation    The place of crime.
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
			if(IsInZone(Killed.Location, KillerPRI.Team.TeamIndex) && FCs[KillerPRI.Team.TeamIndex].Pawn != none && IsInzone(FCs[KillerPRI.Team.TeamIndex].Pawn.Location, KillerPRI.Team.TeamIndex))
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
		if(Killer.Pawn == none || FCs[KillerPRI.Team.TeamIndex].Pawn == none) return;
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
 * Here we update the player scores in EQPlayerInformation.
 *
 * @param Killer     The controller class who is to be rewarded
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
 * Adds the item in array if it does not exist.
 *
 * @param TeamIndex     The team of FCKillers
 * @param Info     The new information
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
 * @param Sender     The Actor class sending the message.
 * @param Receiver   The Controller class receiving the message.
 * @param Message    The real message.
 * @param switch     Category of Message.
 * @param Related_PRI1     Involved PlayerReplicationInfo 1
 * @param Related_PRI2     Involved PlayerReplicationInfo 2
 * @param OptionalObject     Involved Object (Could be a Flag)
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
					   SpectatorBecamePlayer(RelatedPRI_1);
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
 * a spectator.
 *
 * @param SpectatorJoinInfo     The EQPlayerInfo of the player who became spectator
 * @since 0.2.0
 */

 function PlayerBecameSpectator(EQPlayerInformation SpectatorJoinInfo)
 {
	if (bDebugIt)
		Log("PlayerBecameSpectator", LogCompanionTag);
	SpectatorJoinInfo.PlayerBecameSpectator();
	SendEQDataToBackEnd(SpectatorJoinInfo);
 }

/**
 * Here we send the Equalizer player information to the backend.
 *
 * @param EQPlayerInfo     The EQPlayerInfo to be sent to backend
 * @since 0.2.0
 */

 function SendEQDataToBackEnd(EQPlayerInformation EQPlayerInfo)
 {
	local string DataToSend;

	EQPlayerInfo.UpdateScore();
	EQPlayerInfo.PlayersLastPlayingMoment();

	if(EQPlayerInfo.bIsBot)
	{
		return;
    }

    if(HttpClientInstance != none)
	{
		DataToSend = EQPlayerInfo.GenerateArpanString();

		if(DataToSend ~= "")
		{
			return;
		}

		HttpClientInstance.SendData(DataToSend, HttpClientInstance.SubmitEQInfo);
		if (bDebugIt){
			Log("SendEQDataToBackEnd: Sending equalizer data to MySQL database", LogCompanionTag);
			Log(DataToSend, LogCompanionTag);
		}

		EQPlayerInfo.ClearData();
	}
	else
	{
		Log("SendEQDataToBackEnd: Can't find the HttpClient instance", LogCompanionTag);
	}
 }


/**
 * Here we do the necessary arrangements when a spectator
 * becomes player.
 *
 * May wanna call Balancing here!
 *
 * @param SpectatorJoinInfo     The EQPlayerInfo of the spectator who became player
 * @since 0.2.0
 */

 function SpectatorBecamePlayer(PlayerReplicationInfo SpectatorJoinPRI)
 {
	local EQPlayerInformation EQPI;

	EQPI = GetInfoByID(SpectatorJoinPRI.PlayerID);

	if(EQPI != none)
	{
		EQPI.SpectatorBecamePlayer();
	}
	else
	{
		EQPI = SpawnEQPlayerInfo(SpectatorJoinPRI);
		EQPlayers[EQPlayers.Length] = EQPI;
	}

	// We need an improvising balancing algorithm here. Can't shake entire balance for single player! Or can we?!
 }

/**
 * Method to reset sprees.
 *
 * @param TeamIndex    The team of player's whose sprees are to be reset
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
 * Method to reward FCKillers.
 *
 * @param TeamIndex     The team index of Flag, which has FCKillers
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
 * Method to reset FCKillers.
 *
 * @param TeamIndex     The team index of Flag, which has FCKillers
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
 * @param ID     The match ID of the player.
 * @return EQPlayers[i]     The EQPlayerInformation oject associated to the ID
 *         None    If no EQPlayerInformation is associated.
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
 * Method to return the EQPlayerInformation object.
 *
 * @param IdentifierString     The string for identifying the relevant EQPlayerInformation object.
 * @return EQPlayers[i]     The EQPlayerInformation oject associated to the string
 *         None     If no EQPlayerInformation is associated.
 * @since 0.3.6
 */

 function EQPlayerInformation GetInfoByEQIdentifier(string IdentifierString)
 {
	local int i;

	for(i = 0; i < EQPlayers.Length; i++)
	{
		if(IdentifierString ~= EQPlayers[i].EQIdentifier)
		{
			return EQPlayers[i];
		}
	}

	Log("Couldn't locate the EQPlayerInformation object with IdentifierString: " $ IdentifierString, LogCompanionTag);
	return none;
 }

/**
 * Method to check if the Player is in Flag zone.
 *
 * @param SubjectLocation     The physical location of the relevant player
 * @param Team     The team of Flag
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
 * Called when the match ends, keeping suddendeath in mind!
 * This was a cue to send the Equalizer information to backend. Piglet(UK) checked
 * this routine and reported that this leads to duplication of data sent given we
 * are already sending the data when players logout, which itself is called after match
 * ends!
 * So now we destroy the EQPlayerInformation class once we serialize the relevant components of
 * the class and send data to backend.
 *
 * @see #EQGameRules::Trigger
 * @since 0.2.0
 */

 function EndGameEvent()
 {
	local int PlayerIndex;

	if (bDebugIt)
		Log("Match End!!!", LogCompanionTag);

	for(PlayerIndex = EQPlayers.Length - 1; PlayerIndex >= 0; PlayerIndex--)
	{
		if (bDebugIt)
			Log("Send Equalizer information of player: " $ PlayerReplicationInfo(EQPlayers[PlayerIndex].Owner).PlayerName, LogCompanionTag);
		SendEQDataToBackEnd(EQPlayers[PlayerIndex]);
		EQPlayers[PlayerIndex].SetTimer(0.0f, false);
		EQPlayers[PlayerIndex].Destroy();
		EQPlayers.Remove(PlayerIndex, 1);
	}
 }

/**
 * Here we gather the data sent from MySQL database upon relevant query.
 * The Epigraph is of the form OSTRACON,PlayerInfo1,PlayerInfo2,...
 * Finally the PlayerInfo has the following denomination
 * [EQUniqueIdentifer] : [Captures] : ... : [Name]
 *
 * @param Epigraph    The string (as defined above) reveieved from the backend
 * @see #EQHTTPClient::HTTPReceivedData
 * @since 0.3.6
 */

 function GatherAndProcessInformation(string Epigraph)
 {
	local string GString, EQIdentifierString;
	local int NumOfChunks, ChunkIndex, NumOfDenominations, DenominationIndex;
	local EQPlayerInformation EQPlayerInfo;

	//LogEpigraphWithStyle(Epigraph);

	if(GetToken(Epigraph, ",", 0) == "OSTRACON")
	{
		NumOfChunks = GetTokenCount(Epigraph, ",") - 1;
		for(ChunkIndex = 1; ChunkIndex <= NumOfChunks; ChunkIndex++)
		{
			GString = GetToken(Epigraph, ",", ChunkIndex);
			NumOfDenominations = GetTokenCount(GString, ":") - 1;
			for(DenominationIndex = 0; DenominationIndex <= NumOfDenominations; DenominationIndex++)
			{
				if(DenominationIndex == 0)
				{
					EQIdentifierString = GetToken(GString, ":", DenominationIndex);
					EQPlayerInfo = GetInfoByEQIdentifier(EQIdentifierString);
					if(EQPlayerInfo == none)
					{
						Log("EQPlayerInfo is none. Coming out of the loop.", LogCompanionTag);
						break;
					}
					continue;
				}

				EQPlayerInfo.UpdateBackEndData(int(GetToken(GString, ":", DenominationIndex)), DenominationIndex);
			}
			if(EQPlayerInfo != none)
			{
					EQPlayerInfo.MakeActorReadyForEqualizer(true);
			}
		}

		if(false)//bWannaBalance
		{
			Log("Trying to Balance teams.", LogCompanionTag);
			FullBalanceCTFTeams(true, false);
			bWannaBalance = false;
		}
	}
 }

/**
 * We Log the Epigraph string for distinct visibility.
 * Could be optional for ServerAdmin.?
 *
 * @param Epigraph    The Epigraph
 * @see #GatherAndProcessInformation
 * @since 0.3.6
 */

 function LogEpigraphWithStyle(string Epigraph)
 {
	local int EpigraphBoxWidth, SplitStringLength;
	local string LambString;

	EpigraphBoxWidth = 80;
	SplitStringLength = 70;
	LambString = Epigraph;

	ACEPadLog("", "-", "+", EpigraphBoxWidth);
	ACEPadLog("Receieved an Epigraph", " ", "|", EpigraphBoxWidth, true);
	ACEPadLog("[" $ GetDate() $ " | " $ GetTime() $ "]", " ", "|", EpigraphBoxWidth, true);
	ACEPadLog("", "-", "+", EpigraphBoxWidth);

	while(LambString != "")
	{
		if(Len(LambString) >= SplitStringLength)
		{
			ACEPadLog(Mid(LambString, 0, SplitStringLength - 1) $" (=)", " ", "|", EpigraphBoxWidth, true);
			LambString = Mid(LambString, SplitStringLength - 1);
		}
		else
		{
			ACEPadLog(LambString, " ", "|", EpigraphBoxWidth, true);
			LambString = "";
		}
	}

	ACEPadLog("", "-", "+", EpigraphBoxWidth);
 }


//Debug Logging. Saves having to go to the log and trawl through all the other junk
function bool piglogopen()
{
	MyLogfile = Spawn(class'FileLog');
	if (MyLogfile != None)
	{
		MyLogfile.OpenLog("Debug");
		return true;
	}
	else
	{
		return false;
	}
}

function piglogclose()
{
	MyLogfile.CloseLog();
	MyLogfile.Destroy();
}

function piglogwrite(string what)
{
	MyLogfile.Logf(Level.Year $ "-" $ Right("0" $ Level.Month, 2) $ "-" $ Right("0" $ Level.Day, 2) @ Right("0" $ Level.Hour, 2) $ ":" $ Right("0" $ Level.Minute, 2) $ ":" $ Right("0" $ Level.Second, 2)
	@ what);
}

function piglog(string what)
{
	if (piglogopen())
	{
		piglogwrite(what);
		piglogclose();
	}
}

//Balance teams just before map start
function MatchAboutToStart()
{
	if (bBalanceAtMapStart)
	{
			FullBalanceCTFTeams(true, true);
	}

	BMatchAboutToStartDone = true;
}



/**
 * For development and debugging purposes
 *
 * @param MutateString     The string typed by the player
 * @param Sender     Human how typed the command
 * @since 0.1.0
 */

 function Mutate(string MutateString, PlayerController Sender)
 {
	local int ConsoleStringPrintBoxWidth;

	ConsoleStringPrintBoxWidth = 120;

	if(Sender != none && EQUniqueIdentifier.isAdmin(Sender))
	{
		if(MutateString ~= "debugon"){
			bDebugIt = true;
			Sender.ClientMessage("Debug logic: on");
			saveconfig();
		}

		if(MutateString ~= "debugoff"){
			Sender.ClientMessage("Debug logic: off");
			saveconfig();
		}

		if(MutateString ~= "bmson"){
			bBalanceAtMapStart = true;
			Sender.ClientMessage("Balance at map start: on");
			saveconfig();
		}

		if(MutateString ~= "bmsoff"){
			bBalanceAtMapStart = false;
			Sender.ClientMessage("Balance at map start: off");
			saveconfig();
		}

		//show the config items.  At some point just add to the webadmin....
		if (MutateString ~= "balshow"){
			Sender.ClientMessage("Balance Map Start"@bBalanceAtMapStart);
			Sender.ClientMessage("Debug"@bDebugIt);
		}

		//log the current player list and their stats in order
		if(MutateString ~= "logstats"){
			SortEQPInfoArray(BalanceMethod);
			logstats();
		}

		//show the current player list and their stats in order
		if(MutateString ~= "showstats"){
			SortEQPInfoArray(BalanceMethod);
			logstats(Sender);
		}

		//Do a full rebalance, telling only the swapped players. I only see this being needed in extreme circumstances
		if(MutateString ~= "shuffle"){
			FullBalanceCTFTeams(True, False);
		}

		//Piglet: not sure this is needed any longer...and I don't much like ACEPadString :D
		// some dirty stuff was here!
	}

	if (NextMutator != None)
		NextMutator.Mutate(MutateString, Sender);
 }

//////////////////////////////////////////////////////////////////////////////////// Helpers! ////////////////////////////////////////////////////////////////////////////////////
//debug use
function logstats(optional PlayerController Sender)
{  //if sender provided then show stats otherwise debug log
	local byte i;

	if (Owner != None)
	{
		Sender.ClientMessage("Show Stats");
		for(i = 0; i < EQPlayers.Length; i++)
		{
			Sender.ClientMessage(getlogstring(i));
		}
	}
	else
	{
		if (piglogopen())
		{
			piglogwrite("Show Stats");
			for(i = 0; i < EQPlayers.Length; i++)
			{
				piglogwrite(getlogstring(i));
			}
			piglogclose();
		}
		else
		{
			Log("Error: Could not open debug log", LogCompanionTag);
		}
	}
}

//debug use
//A line of player logging of current Value
function string getlogstring(byte i)
{
	local string TheTeam;

	if (EQPlayers[i].bIsBot)
	{
		TheTeam = "Bot ";
	}
	else if (PlayerReplicationInfo(EQPlayers[i].Owner).bOnlySpectator)
	{
		TheTeam = "Spec";
	}
	else if (PlayerReplicationInfo(EQPlayers[i].Owner).Team.TeamIndex ==0)
	{
		TheTeam = "Red ";
	}
	else
	{
		TheTeam = "Blue";
	}

	return pad(i,2)@pad(PlayerReplicationInfo(EQPlayers[i].Owner).PlayerName,20) @ TheTeam @ " : " $ EQPlayers[i].BPValue(BalanceMethod);

}

//debug use
//nice even length strings for logging!
function string pad(coerce string what, int max)
{
	local int strl;

	strl = len(what);

	if (strl == max)
	{
		return what;
	}

	if (strl < max)
	{
		while (len(what) < max) what $= " ";
		return what;
	}

	if (strl > max)
	{
		return left(what, max);
	}
}


// This section has been ripped directly from https://github.com/stijn-volckaert/IACE/blob/dcdce5e1d8a796e663f1de9960a7cb2a8030e397/Classes/IACECommon.uc#L276-L320
// without Anth's permission. But yeah, it is GitHub baby!

// =============================================================================
// ACEPadLog ~ Log with padding (yeah we don't mangle the names!)
//
// @param LogString    string to be logged
// @param PaddingChar  character to fill up the line with (default " ")
// @param FinalChar    character to be placed at the beginning and end of the line (default "|")
// @param StringLength length of the resulting string (default 75)
// @param bCenter      Center the logstring inside the resulting string?
//
// example:
// ACEPadLog("TestString",".","*",30,true)
// => "*.........TestString.........*"
// =============================================================================
function ACEPadLog(string LogString, optional string PaddingChar, optional string FinalChar,
    optional int StringLength, optional bool bCenter)
{
	local string Result;
	local int Pos;

	// Init default properties
	if (PaddingChar == "") PaddingChar  = " ";
	if (FinalChar == "")   FinalChar    = "|";
	if (StringLength == 0) StringLength = 75;

	Result = LogString;

	// Truncate string if needed
	if (Len(Result) + 4 > StringLength)
	{
		Result = FinalChar $ PaddingChar
		$ Left(Result, Len(Result) - 6) $ "..."
		$ PaddingChar $ FinalChar;
	}
	else
	{
		// Insert padding characters
		Result = PaddingChar $ Result;
		while (Len(Result) + 2 < StringLength)
		{
			// Only insert padding at the left side if the original string
			// should be centered in the resulting string
			if (bCenter && (Pos++) % 2 == 1)
				Result = PaddingChar $ Result;
			else
				Result = Result $ PaddingChar;
		}
		Result = FinalChar $ Result $ FinalChar;
	}

	Log(Result, LogCompanionTag);
}

function string ACEPadString(string RString, optional string PaddingChar, optional string FinalChar,
    optional int StringLength, optional bool bCenter)
{
	local string Result;
	local int Pos;

	// Init default properties
	if (PaddingChar == "") PaddingChar  = " ";
	if (FinalChar == "")   FinalChar    = "|";
	if (StringLength == 0) StringLength = 75;

	Result = RString;

	// Truncate string if needed
	if (Len(Result) + 4 > StringLength)
	{
		Result = FinalChar $ PaddingChar
		$ Left(Result, Len(Result) - 6) $ "..."
		$ PaddingChar $ FinalChar;
	}
	else
	{
		// Insert padding characters
		Result = PaddingChar $ Result;
		while (Len(Result) + 2 < StringLength)
		{
			// Only insert padding at the left side if the original string
			// should be centered in the resulting string
			if (bCenter && (Pos++) % 2 == 1)
				Result = PaddingChar $ Result;
			else
				Result = Result $ PaddingChar;
		}
		Result = FinalChar $ Result $ FinalChar;
	}

    return Result;
}

// =============================================================================
// GetToken ~ Retrieve a token from a tokenstring
//
// @param GString    The String in which the token should be found
// @param Delimiter The String that seperates the tokens
// @param Token     The Token that should be retrieved (starting from 0)
// =============================================================================
function string GetToken(string GString, string Delimiter, int Token)
{
	local int I;

	Gstring = GString $ Delimiter;

	for (I = 0; I < Token; ++I)
	{
		if (InStr(GString, Delimiter) != -1)
		{
			GString = Mid(GString, InStr(GString, Delimiter) + Len(Delimiter));
		}
	}

	if (InStr(GString, Delimiter) != -1)
	{
		return Left(GString, InStr(GString, Delimiter));
	}
	else
	{
		return GString;
	}
}

// =============================================================================
// GetTokenCount ~ Calculates the number of tokens in a tokenstring
// Specifically tailored to take care of NameSpace delimiter.
// (check NameSpace definition at https://github.com/ravimohan1991/Equalizer/blob/main/WebScripts/EqualizerBE/Developing.md)
//
// @param GString    The String that contains the tokens
// @param Delimiter The String that seperates the tokens
// =============================================================================
function int GetTokenCount(string GString, string Delimiter)
{
	local int I;

	GString = GString $ Delimiter;

	while (InStr(GString, Delimiter) != -1)
	{
		if(Mid(GString, InStr(GString, Delimiter) + Len(Delimiter), 1) == " ")
		{
		 	// We are in the name field now
			return I + 1;
		}

		GString = Mid(GString, InStr(GString, Delimiter) + Len(Delimiter));
		I++;
	}

	return I;
}

// =============================================================================
// GetDate ~ Get the current date in dd-MM-yyyy format
// =============================================================================
function string GetDate()
{
	return "" $ IntToStr(Level.Day, 2) $ "-" $ IntToStr(Level.Month, 2) $ "-" $ IntToStr(Level.Year, 2);
}

// =============================================================================
// GetTime ~ Get the current time in hh:mm:ss format
// =============================================================================
function string GetTime()
{
	return "" $ IntToStr(Level.Hour, 2) $ ":" $ IntToStr(Level.Minute, 2) $ ":" $ IntToStr(Level.Second, 2);
}

// =============================================================================
// IntToStr ~ Converts an integer to a string of the specified length
//
// @param i            The integer to be converted
// @param StringLength The desired length of the string.
//                     "0" characters are prepadded to the int if needed
// =============================================================================
function string IntToStr(int i, int StringLength)
{
	local string Result;
	Result = string(i);
	while (Len(Result) < StringLength)
		Result = "0"$Result;
	return Result;
}

//kick off a routine to monitor the player numbers etc. This will happen after intial map starting balancing
function MatchStarting()
{
	local class<TeamSizeBalancer> MyTeamSizeBalancerClass;

	if (!bMidGameMonitoring) return;

	if (bDebugIt) Log("******   MatchStarting", LogCompanionTag);

	MyTeamSizeBalancerClass = class<TeamSizeBalancer>(DynamicLoadObject(TeamSizeBalancerClass, class'Class'));
	if(MyTeamSizeBalancerClass != none)
	{
		if (bDebugIt)
		{
			Log("Successfully loaded MyTeamSizeBalancerClass class"@TeamSizeBalancerClass, LogCompanionTag);
		}
	}
	else
	{
		Log("Cannot loaded MyTeamSizeBalancerClass class"@TeamSizeBalancerClass, LogCompanionTag);
	}

	MyTeamSizeBalancer = Spawn(MyTeamSizeBalancerClass, self);
	if(MyTeamSizeBalancer != none)
	{
		if (bDebugIt)
		{
			Log("Successfully spawned MyTeamSizeBalancer instance", LogCompanionTag);
		}
	}
	else
	{
		Log("Cannot spawn MyTeamSizeBalancerClass class"@TeamSizeBalancerClass, LogCompanionTag);
	}

	MyTeamSizeBalancer.MyMut = self;
}

function int differenceToTeam(int diff)
{
	//difference to team number (-1 when same)
	if (diff < 0)
	{
		diff = 0;
	}
	else if (diff > 0)
	{
		diff = 1;
	}
	else
	{
		diff = -1;
	}
	// report to police :)
	// we may wanna think why this happens in the fist place?
	return 100;
}

function PlayerJoiningGame(out string Portal, out string Options)
{
	//Pick the best team for any joining player. Lowest player count team, lower score team, random...in order
	local int iTempInt, iTempInt2;
	local string sTempStr;
	local int ScoreTeam, SizeTeam, team;

	SizeTeam = differenceToTeam(Level.Game.GameReplicationInfo.Teams[0].size - Level.Game.GameReplicationInfo.Teams[1].size);
	if (SizeTeam != -1)
	{
		team = SizeTeam;
	}
	else
	{
		ScoreTeam = differenceToTeam(Level.Game.GameReplicationInfo.Teams[0].Score - Level.Game.GameReplicationInfo.Teams[1].Score);
		if  (ScoreTeam != -1)
		{
			team = ScoreTeam;
		}
		else
		{
			team = Rand(1);
		}
	}

	iTempInt = InStr(Caps(Options), "?TEAM=");
	sTempStr = Mid(Options, iTempInt + 1);
	iTempInt2 = InStr(sTempStr, "?");
	if (iTempInt2 != -1)
	{
		sTempStr = Left(Options, iTempInt) $ "?Team="$team$Mid(sTempStr, iTempInt2);
	}
	else
	{
		sTempStr = Left(Options, iTempInt) $ "?Team="$team;
	}
	Options = sTempStr;
}


 defaultproperties
 {
    Version="0.4.0"
    BuildNumber=20220129
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
    UniqueIdentifierClass="Equalizer_TC_alpha1.UniqueIdentifier"
    TeamSizeBalancerClass="Equalizer_TC_alpha1.TeamSizeBalancer"
    QueryServerHost="localhost"
    QueryServerFilePath="/EqualizerBE/eqquery.php"
    QueryServerPort=80
    MaxTimeout=10
    bLogTeamsRollCall=true
    bShowTeamsRollCall=false
    BalanceMethod=0
    MinimumTimePlayed=30
    bBalanceAtMapStart=true
    bMidGameMonitoring=false
    bDebugIt=true
    LogCompanionTag=Equalizer_some_super_duper_cool_Name
 }
