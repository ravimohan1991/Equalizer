# UniqueIdentifier
## The Need
Since Equalizer generates and maintains its own database (PHP BackEnd), it becomes important to have a scheme which can identify the Human players uniquely. Now UT2004 has GUID for recognizing players, but some more useful and apt algorithm may be deployed for the purpose. Now it might so happen that the algorithm need be private to prevent spoof generation. Enter the ```UniqueIdentifier``` class!

##

This is an example of how a serverside class can use the player identification scheme (see [154b235](https://github.com/ravimohan1991/Equalizer/commit/154b235452e8d6ca79858ba0930beeabcfd3d0c0)). Clients don't need to download and know how the algorithm to compute unique identification is implemented.

```Java
class UniqueIdentifier extends Actor config (Equalizer);

var string IdentifierString;

function postbeginplay()
{
	Log("UniqueIdentifier Initialized", 'UniqueIdentifer');
	super.PostBeginPlay();
}

function string GetIdentifierString(int PlayerID)
{
	//Implement the algorithm here
	return IdentifierString;
}
```

Compile this script in a seperate package and suitably name it (for example ```UniqueIdentifier```). If you are using a dedicated configuration file (UPKG for instance), you may want to set the flags as follows
```
[Flags]
AllowDownload=False
ClientOptional=True
ServerSideOnly=False
```
This would allow the UniqueIdentifier logic to run on server without forcing any kind of download on clients.


Once that is done, configure the Equalizer.ini

INI setting | Default value | Description
------------|---------------|-------------
`UniqueIdentifierClass` | UniqueIdentifier.UniqueIdentifier | The \<PackageName\>.\<ClassName\> for the serverside class.
