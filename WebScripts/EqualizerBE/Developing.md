# Guidelines for future development
Here we will chalk out the framework which will facilitate the development of two decoupled components of Equalizer which include front-end written in unrealscript and PHP based backend.

At this point in time, the PHP script [eqquery.php](https://github.com/ravimohan1991/Equalizer/blob/760a37227475e4e53ed66ad2dc7f458229dd0cbf/WebScripts/EqualizerBE/eqquery.php) accepts two
types of queries
* arpan: for submitting the EQPlayerInformation to the MySQL database for preservation and memory purposes.
* arzi: for querying the MySQL database to get the desired information about a player on the server.

The PHP query is supposed to be made as follows

```PHP
something/EqualizerBE/eqquery.php?arpan=EQPlayerInformation1,EQPlayerInformation2...
```
The format of EQPlayerInformation should be exactly same on PHP and uscript sides. For now, the PHP format (in [main.php](https://github.com/ravimohan1991/Equalizer/blob/760a37227475e4e53ed66ad2dc7f458229dd0cbf/WebScripts/EqualizerBE/main.php)) is 
```PHP
$columnArray[0] = "EQIdentifier";
$columnArray[1] = "Captures";
$columnArray[2] = "Grabs";
$columnArray[3] = "Covers";
$columnArray[4] = "Seals";
$columnArray[5] = "FlagKills";
$columnArray[6] = "TeamKills";
$columnArray[7] = "Points";
$columnArray[8] = "TimePlayedMinutes";
$columnArray[9] = "TimePlayedHours";
$columnArray[10] = "EQName";
```

The generated string is as follows
```PHP
EQIdentifier:Captures:Grabs:Covers:Seals:FlagKills:TeamKills:Points:TimePlayedMinutes:TimePlayedHours:EQName
```
It corresponds to the information related to one player. Several player information can be combined with the delimiter "," as shown above in the PHP query example.

On the uscript side the relevant areas of importance is in [EQPlayerinformation.uc](https://github.com/ravimohan1991/Equalizer/blob/760a37227475e4e53ed66ad2dc7f458229dd0cbf/Classes/EQPlayerInformation.uc#L244-L266)
as follows

```UnrealScript
function string GenerateArpanString()
 {
 	local string ReturnString;
 	local string PlayerName;

 	if(PlayerReplicationInfo(Owner) != none)
 	{
 		PlayerName = PlayerReplicationInfo(Owner).PlayerName;
 	}
 	else
 	{
 		Log("No PlayerReplicationInfo associated with the EQPlayerInformation. Assigning default name for record keeping", 'Equalizer');
 		PlayerName = "NONAME_StreetRat";
 	}

 	ReturnString = EQIdentifier $ ":" $ Captures $ ":" $ Grabs $ ":"
 		$ Covers $ ":" $ Seals $ ":" $ FlagKills $ ":" $ TeamKills
 		$ ":" $ Score $ ":" $ TimePlayedMinutes $ ":"
 		$ TimeplayedHours $ ":" $ PlayerName;

 	Log("Generated arpan string: " $ ReturnString);
 	return ReturnString;
 }
```
