class TeamSizeBalancer extends Actor;

var Equalizer MyMut;

function BeginPlay()
{
	Log("Successfully spawned TeamSizeBalancer instance", 'Equalizer_TC_alpha1');

	if(MyMut.bDebugIt)
	{
		Log("If debugit - test Successfully", 'Equalizer_TC_alpha1');
	}

	setTimer(2, true);

}

function Timer()
{
	Log("Tick");
}