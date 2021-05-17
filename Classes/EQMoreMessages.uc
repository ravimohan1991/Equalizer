/*
 *   --------------------------
 *  |  EQMoreMessages.uc
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
 * This Class contains the Seal, Cover and SpawnKill messages which
 * are displayed to all the Players in green color.
 *
 * TODO: Add the appropriate sounds (if found!!!)
 *
 * @author The_Cowboy
 * @since 0.1.0
 */

class EQMoreMessages extends CriticalEventPlus;

/*
 * Global Variables
 */

 var localized string CoverMessage;
 var localized string CoverSpreeMessage;
 var localized string UltraCoverMessage;
 var localized string SealMessage;
 var localized string SpawnKillMessage;

/**
 * The function gets called by the Level.Game.BroadcastLocalized through
 * the BroadcastHandler
 *
 * @param Switch Identification number of multiple messages.
 * @param RelatedPRI_1 PlayerReplicationInfo of the involved player. Eg The_Cowboy in "The_Cowboy is sealing off the base!"
 * @param RelatedPRI_2 PlayerReplicationInfo of another involved player.
 * @param OptionalObject Nothing
 *
 * @see Equalizer.EvaluateKillingEvent
 * @since 0.1.0
 */

  static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
 {
	if(RelatedPRI_1 == none)
	   return "";

    switch(Switch){
       case 0:  // Cover
          return RelatedPRI_1.PlayerName @ default.CoverMessage;
          break;
       case 1:  // CoverSpree
          return RelatedPRI_1.PlayerName @ default.CoverSpreeMessage;
          break;
       case 2:  // UltraCover
          return RelatedPRI_1.PlayerName @ default.UltraCoverMessage;
          break;
       case 3:  // Seal
          return RelatedPRI_1.PlayerName @ default.SealMessage;
          break;
    }
 }

/**
 * The function also gets called by the Level.Game.BroadcastLocalized through
 * the BroadcastHandler
 *
 * @param Switch Identification number of multiple messages.
 * @param RelatedPRI_1 PlayerReplicationInfo of the involved player. Eg The_Cowboy in "The_Cowboy is sealing off the base!"
 * @param RelatedPRI_2 PlayerReplicationInfo of another involved player.
 * @param OptionalObject Nothing
 *
 * @see Equalizer.EvaluateKillingEvent
 * @since version 0.1.0
 */

 static function ClientReceive(
    PlayerController P,
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
 {
    //local sound NewSound;

    Super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
    switch(Switch){

       case 0:
       case 1:
         /* NewSound = Sound(DynamicLoadObject(Default.CoverMessage, class'Sound', true));
          if(NewSound != none)
             P.PlayAnnouncement(NewSound, 1, true);
          else
             Log("Can't load new sound from AnnouncerClassic");*/
          break;
    }
 }

 defaultproperties
 {
    CoverMessage="covered the Flag Carrier!"
    CoverSpreeMessage="is on a cover spree!"
    UltraCoverMessage="got a multi cover!"
    SealMessage="is sealing off the base!"
    SpawnKillMessage="is a spawnkilling lamer!"
    PosY=0.95
    DrawColor=(B=0,G=255,R=0)
 }
