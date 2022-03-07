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
 * This class parses and generates relevant queries for Equalizer's WebAdmin
 * pages. This is an interface between Equalizer mutator (in-game) and WebServer.
 *
 * @author Epic and The_Cowboy
 * @since 0.3.0
 */

class EQWebAdminQuery extends xWebQueryHandler config;

/*
 * Global Variables
 */

 /*
 * Configurable variables for identifying the .htm/.inc files
 */
 var config string CurrentIndexPage;		// This is the page with the Menu
 var config string CurrentPlayersPage;
 var config string CurrentGamePage;
 var config string CurrentConsolePage;
 var config string StatTableRow;
 var config string RedStatTable;
 var config string BlueStatTable;

 var localized string NoPlayersConnected;
 var localized string CurrentLinks[6];

 /*
 * Reference to mutator Actor
 */
 var Equalizer EQMut;

/**
 * Initializing sequence.
 *
 * @see #UTServerAdmin::LoadQueryHandlers()
 * @since 0.3.0
 */

 function bool Init()
 {
	local Mutator M;

 	for (M = Level.Game.BaseMutator; M != None; M = M.NextMutator)
 	{
 		if(InStr(String(M.Class), "Equalizer") > -1)
 		{
 			EQMut = Equalizer(M);
 			if(EQMut != none)
 			{
 				Log("Goccha! The Equalizer." $ EQMut.Tag, 'Equalizer');
 				break;
 			}
 		}
	}
 	if(EQMut == none)
 	{
 		Log("Cant't associate Equalizer mutator with EQWebAdminQuery", 'Equalizer');
 		return false;
 	}

 	return true;
}

/**
 * Case by case dealing of the queries as they come!
 *
 * @see #EQWebAdminServer::Query(WebRequest Request, WebResponse Response)
 * @since 0.3.0
 */

 function bool Query(WebRequest Request, WebResponse Response)
 {
 	if(EQMut == none)
 	{
 		Log("Can't find the Equalizer in the server mutator list. All queries are redundant now!", 'Equalizer');
 		return false;
 	}

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

 		case CurrentGamePage:
 			if (!MapIsChanging())
 				QueryCurrentGame(Request, Response);
 			return true;
 	}
	return false;
 }

/**
 * The current frame displaying the page with PlayerList and various Equalizer operations.
 *
 * @see Query(WebRequest Request, WebResponse Response)
 * @since 0.3.0
 */
 
 function QueryCurrentFrame(WebRequest Request, WebResponse Response)
 {
 	local String Page;

 	// if no page specified, use the default
 	Page = Request.GetVariable("Page", CurrentGamePage);

 	Log("In the EQwebAdminQuery, the Page string is: " $ Page);

 	Response.Subst("IndexURI", 	CurrentIndexPage$"?Page="$Page);
 	Response.Subst("MainURI", 	Page);

 	ShowFrame(Response, DefaultPage);
 }

/**
 * Query related to menu on the left.
 *
 * @see Query(WebRequest Request, WebResponse Response)
 * @since 0.3.0
 */
 
 function QueryCurrentMenu(WebRequest Request, WebResponse Response)
 {
	local String Page;

 	Page = Request.GetVariable("Page", CurrentGamePage);

 	// set background colors
 	Response.Subst("DefaultBG", DefaultBG);	// for unused tabs

 	switch(Page)
 	{
 		case CurrentGamePage:
 				Response.Subst("GameBG", 	HighlightedBG);
 			break;
 	}

 	// Set URIs
 	Response.Subst("GameURI",		DefaultPage$"?Page="$CurrentGamePage);
	//Response.Subst("ConsoleURI", 	DefaultPage$"?Page="$CurrentConsolePage);

 	// Set link text
 	Response.Subst("GameLink", 		CurrentLinks[0]);

	ShowPage(Response, CurrentIndexPage);
 }

/**
 * This routine deals with generation of team tables with appropriate
 * filling of playernames along with the Equalizer's metric.
 * Should be useful for monitoring purposes!
 *
 * @see Query(WebRequest Request, WebResponse Response)
 * @since 0.3.0
 */

 function QueryCurrentGame(WebRequest Request, WebResponse Response)
 {
 	local string SwitchButtonName;
 	local string RedGameState, BlueGameState;
 	local Controller C;
 	local TeamPlayerReplicationInfo PRI;
 	local EQPlayerInformation EQPInfo;

 	if (CanPerform("Mt|Mm"))
 	{
 		RedGameState = "";
 		BlueGameState = "";

 		// Show game status if admin has necessary privs
 		// Here we shall modify the code for displaying the player list in teams and relevant PPHs
 		if (CanPerform("Ma"))
 		{
 			if (Level.Game.NumPlayers + Level.Game.NumBots > 0)
 			{
 				for (C = Level.ControllerList; C != None; C = C.NextController)
 				{
 					PRI = None;
 					EQPInfo = None;
 					if (!C.bDeleteMe)
 					{
 						if (TeamPlayerReplicationInfo(C.PlayerReplicationInfo) != None)
 						{
 							PRI = TeamPlayerReplicationInfo(C.PlayerReplicationInfo);
 						}

 						if (PRI != None)
 						{
 							if(PRI.Team.TeamIndex == 0) // Red team
 							{
 								EQPInfo = EQMut.GetInfoByID(PRI.PlayerID);

 								if(EQPInfo == None)
 								{
 									Log("Can't find EQPlayerInformation associated with Player: " $ PRI.PlayerName, 'Equalizer');
 									return;
 								}

 								if(PRI.bBot)
 								{
 									Response.Subst("PlayerName", HtmlEncode(PRI.PlayerName $ "(BOT)"));
 								}
 								else
 								{
 									Response.Subst("PlayerName", HtmlEncode(PRI.PlayerName));
 								}

 								Response.Subst("PPH", string(int(EQPinfo.PPH)));
 								RedGameState $= WebInclude(StatTableRow);
 							}
 							else if(PRI.Team.TeamIndex == 1) // Blue team
 							{
 								EQPInfo = EQMut.GetInfoByID(PRI.PlayerID);

 								if(EQPInfo == None)
 								{
 									Log("Can't find EQPlayerInformation associated with Player: " $ PRI.PlayerName, 'Equalizer');
 									return;
 								}

 								if(PRI.bBot)
 								{
 									Response.Subst("PlayerName", HtmlEncode(PRI.PlayerName $ "(BOT)"));
 								}
 								else
 								{
 									Response.Subst("PlayerName", HtmlEncode(PRI.PlayerName));
 								}
								Response.Subst("PPH", string(int(EQPinfo.PPH)));
								BlueGameState $= WebInclude(StatTableRow);
 							}
 						}
 					}
 				}
 			}
			else
 			{
 				RedGameState = "<tr><td colspan=\"6\" align=\"center\">"@NoPlayersConnected@"</td></tr>";
 				BlueGameState = "<tr><td colspan=\"6\" align=\"center\">"@NoPlayersConnected@"</td></tr>";
 			}

 			Response.Subst("StatRows", RedGameState);
 			Response.Subst("RedGameState", WebInclude(RedStatTable));

 			Response.Subst("StatRows", BlueGameState);
 			Response.Subst("BlueGameState", WebInclude(BlueStatTable));
 		}

 		MapTitle(Response);
 		ShowPage(Response, CurrentGamePage);
 	}
 	else AccessDenied(Response);
 }


defaultproperties
{
    DefaultPage="currentframe"
    CurrentGamePage="current_game"
    Title="the_prestige"
    CurrentIndexPage="current_menu"
    StatTableRow="current_game_stat_table_row"
    NoPlayersConnected="** No Players Connected **"
    RedStatTable="current_game_red_stat_table"
    BlueStatTable="current_game_blue_stat_table"
    CurrentLinks[0]="Current Game Scenario"
    NeededPrivs="X|K|M|Xs|Xc|Xp|Xi|Kp|Kb|Ko|Mb|Mt|Mm|Mu|Ma" // The privileges for accessing the page
}

