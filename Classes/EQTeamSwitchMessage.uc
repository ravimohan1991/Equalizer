/*
 *   --------------------------
 *  |  EQTeamSwitchMessage.uc
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
 * This Class contains the relevant messages and sounds when the Equalizer
 * switches the team of a Player.
 *
 * @author The_Cowboy
 * @since 0.3.6
 */

class EQTeamSwitchMessage extends CriticalEventPlus;

#exec AUDIO IMPORT FILE="Sounds\YouAreOnRed.wav" NAME="YouAreOnRed"
#exec AUDIO IMPORT FILE="Sounds\YouAreOnBlue.wav" NAME="YouAreOnBlue"

/*
 * Global Variables
 */

 var localized string SwitchToRed;
 var localized string SwitchToBlue;

 var Sound SwitchToRedSound;
 var sound SwitchToBlueSound;

/**
 * The function gets called by the Level.Game.BroadcastLocalized through
 * the BroadcastHandler.
 *
 * @param Switch     Identification number of multiple messages.
 * @param RelatedPRI_1     PlayerReplicationInfo of the involved player. Eg The_Cowboy in "The_Cowboy Team Switch!"
 * @param RelatedPRI_2     PlayerReplicationInfo of another involved player.
 * @param OptionalObject     Nothing
 *
 * @see #EQGameRules.ChangeTeam
 * @since 0.3.6
 */

  static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
 {
	switch(Switch)
	{
		case 0:  // Switch to Red
			if(RelatedPRI_1 != none)
			{
				default.DrawColor.R = 100;
				default.DrawColor.G = 0;
				default.DrawColor.B = 0;
				return RelatedPRI_1.PlayerName @ default.SwitchToRed;
			}
				break;
		case 1:  // Switch to Blue
			if(RelatedPRI_1 != none)
			{
				default.DrawColor.R = 0;
				default.DrawColor.G = 0;
				default.DrawColor.B = 100;
				return RelatedPRI_1.PlayerName @ default.SwitchToBlue;
			}
			break;
	}
 }

/**
 * The function also gets called by the Level.Game.BroadcastLocalized through
 * the BroadcastHandler.
 *
 * @param P     The PlayerController instance of the player on whom the the message is endowed
 * @param Switch     Identification number of multiple messages
 * @param RelatedPRI_1     The PlayerReplicationInfo instance of the involved actor
 * @param RelatedPRI_2     Another PRI, not important in this context
 *
 * @see #EQGameRules.ChangeTeam
 * @since version 0.3.6
 */

 static function ClientReceive(
	PlayerController P,
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
 {
	Super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
	switch(Switch)
	{
		case 0:
			if(default.SwitchToRedSound != none)
			{
				if(P.ViewTarget != none)
					P.ViewTarget.PlaySound(default.SwitchToRedSound, SLOT_Talk, 4, , , , false);
			}
				else
					Log("Can't load SwitchToRedSound sound.", 'Equalizer_TC_alpha');
			break;
		case 1:
			if(default.SwitchToBlueSound != none)
			{
				if(P.ViewTarget != none)
					P.ViewTarget.PlaySound(default.SwitchToBlueSound, SLOT_Talk, 4, , , , false);
			}
				else
					Log("Can't load SwitchToBlueSound sound.", 'Equalizer_TC_alpha');
			break;
	}
 }

 defaultproperties
 {
    SwitchToRed="Team Switch!"
    SwitchToBlue="Team Switch!"
    SwitchToRedSound = Sound'YouAreOnRed'
    SwitchToBlueSound = Sound'YouAreOnBlue'
    PosY=0.50
 }
