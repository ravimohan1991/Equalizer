# Guidelines for future development
Here we will chalk out the framework which will facilitate the development of two decoupled components of Equalizer which include frontend written in UnrealScript and PHP based backend.

At this point in time, the PHP script [eqquery.php](https://github.com/ravimohan1991/Equalizer/blob/760a37227475e4e53ed66ad2dc7f458229dd0cbf/WebScripts/EqualizerBE/eqquery.php) accepts two
types of queries
* arpan: for submitting the EQPlayerInformation to the MySQL database for preservation and memory purposes.
* arzi: for querying the MySQL database to get the desired information about a player on the server.
---------------------
For ```arpan```, the PHP query is supposed to be made as follows

```PHP
something/EqualizerBE/eqquery.php?arpan=EQPlayerInformation1,EQPlayerInformation2...
```
The format of EQPlayerInformation should be exactly same on PHP and uscript sides. For now, the statistics PHP list (in [main.php](https://github.com/ravimohan1991/Equalizer/blob/10ba10b091622889fa4a6d85c7f65ee60ac37d0c/WebScripts/EqualizerBE/main.php#L32-L44)) is 
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
$columnArray[10] = "Frags";
$columnArray[11] = "Suicides";
$columnArray[12] = "EQName";
```

The corresponding string format is as follows
```PHP
EQPlayerInformation=EQIdentifier:Captures:Grabs:Covers:Seals:FlagKills:TeamKills:Points:TimePlayedMinutes:TimePlayedHours:Frags:Suicides:EQName
```
It the information related to one player. Several players' information can be combined with the delimiter "," as shown above in the PHP query example.

On the UnrealScript side the relevant area of importance is in [EQPlayerinformation.uc](https://github.com/ravimohan1991/Equalizer/blob/10ba10b091622889fa4a6d85c7f65ee60ac37d0c/Classes/EQPlayerInformation.uc#L326-L353)
as follows

```UnrealScript
function string GenerateArpanString()
 {
 	...
 	ReturnString = URLEncode(EQIdentifier $ ":" $ Captures $ ":" $ Grabs $ ":"
 		$ Covers $ ":" $ Seals $ ":" $ FlagKills $ ":" $ TeamKills
 		$ ":" $ Score $ ":" $ TimePlayedMinutes $ ":"
 		$ TimeplayedHours $ ":" $ Frags $ ":" $ Suicides $ ": " $ PlayerName); // Note the space given after the last delimiter (:) meaning Name space delimiter

 	return ReturnString;
 }
```
Here we introduce the notion of NameSpace delimiter denoted by symbol ": " (colon followed by space). This is done precisely to indicate and contrast that what follows is a name field which itself can contain the usual delimiter symbol ":" (we refer the reader to [resolved issue 2](https://github.com/ravimohan1991/Equalizer/issues/2)). 

To see the output string generated (with the NameSpace scope, pun intended!), we consult the [URLEncode](https://github.com/ravimohan1991/Equalizer/commit/917ebc0116938655cbc766ac21857abdb19a9069) scheme (suggested by Piglet). Effictively it is a dictionary to translate certain type of single chars to collection of chars. Consider the following little dictionary

| Char          | Translation   | 
| ------------- |:-------------:|
| :             | %3A           |
|  (Space)      | %20           |

then the generated string is

```
Little_Johnny%3A0%3A0%3A0%3A0%3A0%3A0%3A-1.00%3A0%3A0%3A0%3A1%3A%20Johnny%3A_Sins_%3ARe
```

---------------------
For ```arzi```, the PHP query is as follows

```PHP
something/EqualizerBE/eqquery.php?arzi=EQIdentifier1,EQIdentifier2...
```
In UnrealScript side, the following area should be noted ([Equalizer.uc](https://github.com/ravimohan1991/Equalizer/blob/10ba10b091622889fa4a6d85c7f65ee60ac37d0c/Classes/Equalizer.uc#L432-L440))
```UnrealScript
function SendArziToBE(EQPlayerInformation EQPlayerInfo)
 {
	local string ArziString;

	ArziString = EQPlayerInfo.EQIdentifier;//Clustering required?

	Log("Arzi string is: " $ ArziString, 'Equalizer');
 	HttpClientInstance.SendData(ArziString, HttpClientInstance.QueryEQInfo);
 }
```
The PHP script [main.php](https://github.com/ravimohan1991/Equalizer/blob/10ba10b091622889fa4a6d85c7f65ee60ac37d0c/WebScripts/EqualizerBE/main.php#L153-L156) sends the ```arzi``` query response with the **same** NameSpace delimiter, like so
```
OSTRACON,Little_Johnny:3:8:2:0:5:0:70:25:0:13:20: Johnny:_Sins_:Re
```
and on the UnrealScript side it is easily dechiphered by the following modified helper code in [Equalizer.uc](https://github.com/ravimohan1991/Equalizer/blob/10ba10b091622889fa4a6d85c7f65ee60ac37d0c/Classes/Equalizer.uc#L1410-L1429)
```UnrealScript
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
```
