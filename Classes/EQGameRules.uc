/*
 *   --------------------------
 *  |  EQGameRules.uc
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
 * This class is for tracking the Killing events in the Game.
 *
 * @see Equalizer.PostBeginPlay()
 *
 * @author The_Cowboy
 * @see Equalizer.EvaluateKillingEvent
 * @since 0.1.0
 */

class EQGameRules extends Gamerules;

/*
 * Global Variables
 */

 /* The Equalizer Mutator reference */
 var    Equalizer         EQMut;

/**
 * Method to notify Equalizer about the killings.
 *
 * @param Killed The Pawn class getting screwed.
 * @param Killer The Controller class screwing around.
 * @param damageType The nature of damage.
 * @param HitLocation The place of crime.
 *
 * @see #Engine.GameInfo.PreventDeath(Killed, Killer, damageType, HitLocation)
 * @since 0.1.0
 */

 function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
 {

	if ( (NextGameRules != none) && NextGameRules.PreventDeath(Killed, Killer, damageType, HitLocation) )
		return true; // No Killing! So return.

	EQMut.EvaluateKillingEvent(Killed, Killer, damageType, HitLocation);

	return false;
 }

/**
 * For updating the scores of EQPlayerInformation
 *
 * @param Killer The Controller class screwing around.
 * @param Other The Controller class getting screwed.
 *
 * @see #Engine.GameInfo.ScoreKill(Killer, Other)
 * @since 0.2.0
 */

 function ScoreKill(Controller Killer, Controller Killed)
 {
	if(Killer != none)
	{
		EQMut.UpdateEQKillerScore(Killer);
	}
	// We detected a possible suicide. So Killed is essentially the Killer.
	else if(Killed != none)
	{
		EQMut.UpdateEQKillerScore(Killed);
	}

	if ( NextGameRules != None )
		NextGameRules.ScoreKill(Killer,Killed);
 }
