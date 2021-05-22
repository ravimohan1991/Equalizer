# UniqueIdentifier

This is an example of how a serverside class can use the player identification scheme. Clients don't need to download and know how the algorithm to compute unique identification is implemented.

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

Compile this script in a seperate package and suitably name it (for example ```UniqueIdentifier```). Once that is done, configure the Equalizer.ini

INI setting | Default value | Description
------------|---------------|-------------
`UniqueIdentifierClass` | UniqueIdentifier.UniqueIdentifier | The \<PackageName\>.\<ClassName\> for the serverside class.
