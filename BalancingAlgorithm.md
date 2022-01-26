Here we keep track of the evolution of the Balancing Algorithm in its entirety. I believe the basic framework shall remain invariant throughout the entire lifetime of Equalizer.

# The Sauce 
We begin with the commit [abece2d](https://github.com/ravimohan1991/Equalizer/commit/abece2d0584d4e0d8903901787747b9895da28ca). The fundamental idea is like so
- Seperate Bots and Humans
- Sort the EQPlayerInfo (Note to self: Prevent sending Bot's arzi. Don't wanna burden BE with redundant queries) of the Human players with some basis parameter
- FillUp teams in certain fashion
- Restore bot-crowd at the end of the routine

## Seperate Bots and Humans
We refer the reader [here](https://github.com/ravimohan1991/Equalizer/blob/abece2d0584d4e0d8903901787747b9895da28ca/Classes/Equalizer.uc#L300).
```UnrealScript
 function BalanceCTFTeams()
 {
	local int CacheMinPlayers;

	if(EQPlayers.Length == 0)
	{
		Log("There is nothing in the EQPlayers array. Balancing can't happen this way.", 'Equalizer');
		return;
	}

	// We want to seperate bots and Humans
	// which is crucial for balancing during gameplay.
	// Before the match starts, there are no bots.

	// For bot-crowd seperation from Humans and filtering
	CacheMinPlayers = CTFGameInfo.MinPlayers;

	// Bots... don't interfare in Balancing!
	//CTFGameInfo.MinPlayers = 0;
	//CTFGameInfo.KillBots(0);

	SortEQPInfoArray(7);   // BEScore

	// Piglet's algorithm ...
	NuclearShellFillAlgorithm();

	// Restore the bot-crowd
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

Once that is done, we sort the EQPlayerInformation array ```EQPlayers``` based on the outcoming order. Now we start here following Piglet's suggestion (and my inspiration) by filling up the ```Red``` and ```Blue``` team categories, starting with ```Red```, by allowing the highest rated player to be aquired by ```Red``` and porceed downwards with alternating team categories. This mechanism is gonna evolve in time. 

## Restore Bots
Here the variable ```CacheMinPlayers``` is useful and we restore bot-crowd by resetting the number in the ```GameInfo```, meaning, we ensure that total number of individuals playing the Game doen't dip below the pre-decided amount.
