/*
 *   --------------------------
 *  |  EQBroadcastHandler.uc
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
 *   May, 2021      :                         First inscription
 *   September, 2021:                         v0.2.0 Release
 *   January, 2022  :                         Backreactions from Miasma
 */

/**
 * This is a custom Class to manage/intercept the Broadcasted messages
 * for appropriate interpretation. This
 * object is added to the linked list of of BroadcastHandler (Level.Game.BroadcastHandler)
 * by the function Equalizer.RegisterBroadcastHandler().
 *
 * @author The_Cowboy
 * @see Equalizer.EvaluateMessageEvent
 * @since 0.1.0
 */

class EQBroadcastHandler extends BroadcastHandler;

/*
 * Global Variables
 */

 /* The Equalizer Mutator reference */
 var    Equalizer         EQMut;

/**
 * Method to intercept the broadcasted messages.
 *
 * @param Sender The Actor class sending the message.
 * @param Receiver The Controller class receiving the message.
 * @param Message The real message.
 * @param switch Category of Message.
 * @param Related_PRI1 Involved PlayerReplicationInfo 1
 * @param Related_PRI2 Involved PlayerReplicationInfo 2
 * @param OptionalObject Involved Object (Could be a Flag)
 *
 * @see #UnrealGame.CTFMessage
 * @since 0.1.0
 */

 function BroadcastLocalized(Actor Sender, PlayerController Receiver, class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
 {
	EQMut.EvaluateMessageEvent(Sender, Receiver, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);

	super.BroadcastLocalized(Sender, Receiver, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
 }

