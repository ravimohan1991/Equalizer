/*
 *   --------------------------
 *  |  EQWebAdminQuery.uc
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
 * This class generates the WebPages for Equalizer's WebAdmin
 *
 * @author Epic and The_Cowboy
 * @since 0.3.0
 */

class EQWebAdminQuery extends xWebQueryHandler config;

var config string CurrentIndexPage;		// This is the page with the Menu
var config string CurrentPlayersPage;
var config string CurrentGamePage;
var config string CurrentConsolePage;
/*
function bool Query(WebRequest Request, WebResponse Response)
{
	if (!CanPerform(NeededPrivs))
		return false;

	switch (Mid(Request.URI, 1))
	{
	case DefaultPage:
		QueryCurrentFrame(Request, Response);
		return true;

	case CurrentIndexPage:
		QueryCurrentMenu(Request, Response);
		return true;

	case CurrentPlayersPage:
		if (!MapIsChanging())
			QueryCurrentPlayers(Request, Response);
		return true;

	case CurrentGamePage:
		if (!MapIsChanging())
			QueryCurrentGame(Request, Response);
		return true;

	case CurrentConsolePage:
		if (!MapIsChanging())
			QueryCurrentConsole(Request, Response);
		return true;

	case CurrentConsoleLogPage:
		if (!MapIsChanging())
			QueryCurrentConsoleLog(Request, Response);
		return true;

	case CurrentConsoleSendPage:
		QueryCurrentConsoleSend(Request, Response);
		return true;

	case CurrentMutatorsPage:
		if (!MapIsChanging())
			QueryCurrentMutators(Request, Response);
		return true;

	case CurrentBotsPage:
		if (!MapIsChanging())
			QueryCurrentBots(Request, Response);
		return true;

	case CurrentRestartPage:
		if (!MapIsChanging())
			QueryRestartPage(Request, Response);
		return true;
	}
	return false;
}
*/

defaultproperties
{
    DefaultPage="currentframe"
    Title="Current"
    NeededPrivs="X|K|M|Xs|Xc|Xp|Xi|Kp|Kb|Ko|Mb|Mt|Mm|Mu|Ma" // The privileges for accessing the page
}

