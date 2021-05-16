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
 * @version 1.0
 * @since 1.0
 */

class Equalizer extends Mutator config;

/*
 * Global Variables
 */

 /** String with Version of the Mutator */
 var   string                                     Version;
 /** String with Description of the Mutator */
 var   localized cache string                     Description;

 /*
  * Configurable Variables
  */

 var()   config           bool         bActivated;

/**
 * The function gets called just after game begins. So we set up the
 * environmnet for Equalizer to operate.
 *
 * @since version 1A
 */

 function PostBeginPlay()
 {
 	Log("Equalizer Initialized!", 'Equalizer');
 }

 defaultproperties
 {
    Version="1.0"
    Description="Equalizes and encourages CTF team gameplay."
 }
