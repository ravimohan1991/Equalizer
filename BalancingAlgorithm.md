Here we keep track of the evolution of the Balancing Algorithm in its entirety. I believe the basic framework shall remain invariant throughout the entire lifetime of Equalizer.

# The Sauce 
We begin with the commit [abece2d](https://github.com/ravimohan1991/Equalizer/commit/abece2d0584d4e0d8903901787747b9895da28ca). The fundamental idea is like so
- Seperate Bots and Humans
- Sort the EQPlayerInfo (Note to self: Prevent sending Bot's arzi. Don't wanna burden BE with redundant queries) of the Human players with some basis parameter
- FillUp teams in certain fashion
- Restore bot-crowd at the end of the routine

## Seperate Bots and Humans
We refer the reader [here](https://github.com/ravimohan1991/Equalizer/blob/20a282f3dd2d830d465a26de466c121371fb2318/Classes/Equalizer.uc#L339-L372).
```UnrealScript
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
```
In the code we first cache the ```MinPlayers``` which is a variable ensuring that the minimum number of playing individuals (Bots + Humans) on the server doesn't dip below than the specified amount.
Next we issue a function call to remove all the bots in the server and set the ```MinPlayers=0``` for the inevitable reset. Now we are left with just Human players and pure Balancing can be initiated.

## The Balancing
In any computer science degree or any decent algorithm course, selection sort is one of the first algorithms to be discussed and taught. So we will be using just that here. The [code](https://github.com/ravimohan1991/Equalizer/blob/abece2d0584d4e0d8903901787747b9895da28ca/Classes/Equalizer.uc#L382-L399) is written like so
```UnrealScript
function SortEQPInfoArray(int BasisParameter)
 {
	local int i, j;
	local EQPlayerInformation tmp;

	for (i = 0; i < EQPlayers.Length-1; i++)
	{
		for (j = i+1; j < EQPlayers.Length; j++)
		{
			if(!InOrder(EQPlayers[i], EQPlayers[j], BasisParameter))
			{
				tmp = EQPlayers[i];
				EQPlayers[i] = EQPlayers[j];
				EQPlayers[j] = tmp;
			}
		}
	}
 }
```
The discussion of the function ```InOrder``` is important in this context. We parametrize the order deduction based on the data sent by BackEnd (BE). We can compute from a simple PPH to ELO (based on CTF statistics trackers) covering the entire range of desired complexities. It is crucial to note that besides the BE data, there are other complexities, based on the player's current state, which need be (pun intended!) included in computing the order.

In the commit [2c50dca](https://github.com/ravimohan1991/Equalizer/commit/2c50dca77deb8c11f63687c8254fc8c97d305533) (the branch [miasmactivity](https://github.com/ravimohan1991/Equalizer/tree/miasmactivity)), the Admin decides to leverage PPH for the order estimation. It is evident from [here](https://github.com/ravimohan1991/Equalizer/blob/20a282f3dd2d830d465a26de466c121371fb2318/Classes/EQPlayerInformation.uc#L204-L216), https://github.com/ravimohan1991/Equalizer/blob/20a282f3dd2d830d465a26de466c121371fb2318/Classes/EQPlayerInformation.uc#L261 and https://github.com/ravimohan1991/Equalizer/blob/20a282f3dd2d830d465a26de466c121371fb2318/Classes/Equalizer.uc#L1995. Once the estimation is done, we sort the EQPlayerInformation array ```EQPlayers``` in descending order. 

Now we start here following Piglet's suggestion (and my inspiration) by filling up the ```Red``` and ```Blue``` team categories, starting with ```Red```, by allowing the highest rated player to be acquired by ```Red``` and next two highest rated players be acquired by ```Blue```, like so (written [here](https://github.com/ravimohan1991/Equalizer/blob/20a282f3dd2d830d465a26de466c121371fb2318/Classes/Equalizer.uc#L382-L429))
```UnrealScript
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
```

## Restore Bots
Here the variable ```CacheMinPlayers``` is useful https://github.com/ravimohan1991/Equalizer/blob/20a282f3dd2d830d465a26de466c121371fb2318/Classes/Equalizer.uc#L371 and we restore bot-crowd by resetting to the number (set in the relevant .ini) in the ```GameInfo```, meaning, we ensure that total number of individuals playing the Game doesn't dip below the pre-decided amount.

Note that it might happen some players flee or the players' difference between ```Red``` and ```Blue``` is not zero. This code (as in current state) doesn't do anything about that. Miasma supplements that by running a Private code snippet. I shall look into this issue later.
