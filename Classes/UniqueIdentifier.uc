class UniqueIdentifier extends Actor config;

var string IdentifierString;

function postbeginplay()
{
	super.PostBeginPlay();
}

function string GetIdentifierString(int PlayerID){

	return "Foo";
}	


function bool isAdmin(PlayerController p){

	return p.PlayerReplicationInfo.bAdmin;
}	


