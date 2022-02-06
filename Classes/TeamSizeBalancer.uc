class TeamSizeBalancer extends Actor;

var Equalizer MyMut;

function BeginPlay()
{
	Log("Successfully spawned TeamSizeBalancer instance", class'Equalizer'.default.LogCompanionTag);

	if(MyMut.bDebugIt)
	{
		Log("If debugit - test Successfully", class'Equalizer'.default.LogCompanionTag);
	}

	setTimer(2, true);

}

function Timer()
{
	Log("Tick");
}
