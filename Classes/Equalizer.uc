/*
 *   --------------------------
 *  |  Equalizer.uc
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
 * Equalizer is a Mutator which makes sure that the CTF matches are 		<br />
 * played between teams of equal calibre. It will further acknowledge and   <br />
 * encourage the team gameplay leading to a justly competitive match.		<br />
 * The aim is to gauge the match awareness, reactivity and commitment		<br />
 * towards CTF goals.								<br />
 *
 * @author The_Cowboy
 * @since 0.1.0
 */

class Equalizer extends Mutator config(Equalizer);

/*
 * Global Variables
 */

 /** String with Version of the Mutator */
 var   string                                     Version;

 /*
  * Configurable Variables
  */

 var()   config           bool         bActivated;

/**
 * The function gets called just after game begins. So we set up the
 * environmnet for Equalizer to operate.
 *
 * @since version 0.1.0
 */

 function PostBeginPlay()
 {
    local EQGameRules EQGRules;

 	Log("Equalizer (v"$Version$") Initialized!", 'Equalizer');
 	EQGRules = Level.Game.Spawn(class'EQGameRules'); // for accessing PreventDeath function
 	EQGRules.EQMut = self;
 	Level.Game.AddGameModifier(EQGRules);// register the GameRules Modifier
 }

/**
 * Method to evaluate Covers, Seals and all that.
 *
 * @param Killed The Pawn class getting screwed.
 * @param Killer The Controller class screwing around.
 * @param damageType The nature of damage.
 * @param HitLocation The place of crime.
 *
 * TODO: Rigorously test the Cover/Seal Hypothesis
 *
 * @see #EQGameRules.PreventDeath(Killed, Killer, damageType, HitLocation)
 * @since version 0.1.0
 * authors of this routine can be found at http://wiki.unrealadmin.org/SmartCTF
 */

 function EvaluateKillingEvent(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
 {
  	Log("Killed "$Killed.PlayerReplicationInfo.PlayerName$" Killer "$Killer.PlayerReplicationInfo.PlayerName, 'Equalizer');
 }


 defaultproperties
 {
    Version="0.1.0"
    Description="Equalizes and encourages CTF team gameplay."
    FriendlyName="DivineJustice"
 }
