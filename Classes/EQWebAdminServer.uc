/*
 *   --------------------------
 *  |  EQWebAdminServer.uc
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
 * The class responsible for instantiating and then maintaining
 * the WebAdmin relevant functioning.
 *
 * @author Epic, Rush, and The_Cowboy
 * @since 0.3.0
 */

class EQWebAdminServer extends UTServerAdmin config;


/**
 * We setup the environment for Equalizer's WebAdmin interface.
 *
 * @since 0.3.0
 */

 event Init()
 {
	local UTServerAdmin UTSA;
	local byte index;

	for(index = 0; index < 10; index++)
	{
		if(WebServer.ApplicationObjects[index] != none && WebServer.ApplicationObjects[index].IsA('UTServerAdmin'))
		{
			UTSA = UTServerAdmin (WebServer.ApplicationObjects[index]);
			Spectator = UTSA.Spectator;
			Log("The WebAdmin Spectator is: " $ Spectator.Tag);
			GamePI = UTSA.GamePI;
			//CurAdmin = UTSA.CurAdmin;
			Log("Successfully assigned WebAdmin's variables relevant to EQWebAdmin. Judicious eh!", 'Equalizer');
			break;// Assumption: UTServerAdmin be the first in the list of ApplicaitonObjects declaration!
		}
	}

	if(UTSA == none)
	{
		Log("Couldn't find WebAdmin instance of the Game.", 'Equalizer');
		return;
	}

	QueryHandlerClasses.Remove(0, QueryHandlerClasses.Length);  // Jugaad for now!
	if(QueryHandlerClasses.Length == 0)
	{
		QueryHandlerClasses[0] = "Equalizer" $ class'Equalizer'.default.Version $ class'Equalizer'.default.BuildNumber $ ".EQWebAdminQuery";
		Log("QueryHandlerClass: " $ QueryHandlerClasses[0]);
	}

	// won't change as long as the server is up and the map hasnt changed
	LoadQueryHandlers();

	// we are not disturbing them, for now!
	//AExcMutators = New(None) class'StringArray';
	//AIncMutators = New(None) class'SortedStringArray';

	ReplaceText( Initialized, "%class%", string(Class) );
	ReplaceText( Initialized, "%port%", string(WebServer.ListenPort) );
	Log(Initialized,'Equalizer');
 }


// =====================================================================================================================
// =====================================================================================================================
//  Server Management & Control
// =====================================================================================================================
// =====================================================================================================================

 function LoadSkins()
 {
	local string 			S;
	local class<WebSkin> 	SkinClass;

	Skins = new(None) class'StringArray';
	S = "Equalizer" $ class'Equalizer'.default.Version $ class'Equalizer'.default.BuildNumber $ ".EQWebSkin";
	Log("The String being dynamically loaded is: " $ S);

	SkinClass = class<WebSkin>(DynamicLoadObject(S, class'Class'));
	if (SkinClass != None)
	{
		Skins.Add(Level.GetItemName(string(SkinClass)), SkinClass.default.DisplayName);
		WebSkins[WebSkins.Length] = SkinClass;
	}

	ApplySkinSettings();
 }

 function string SetGamePI(optional string GameType)
 {
	return "";
 }


 function ApplySkinSettings()
 {
	CurrentSkin = new(None) WebSkins[0];
	CurrentSkin.Init(Self);

	Log("Current Skin is: " $ CurrentSkin.default.DisplayName $ " with css files as: " $ CurrentSkin.default.SkinCSS);
 }


// Page Generations

 event Query(WebRequest Request, WebResponse Response)
 {
 	local byte i;
	Log("WebRequest Response");

	// Ok so this the the place were the query first appears in the web applicaiton

	//Response.Subst("BugAddress", "webadminbugs"$Level.EngineVersion$"@epicgames.com");

	//Modify a substitution variable which will be used during the IncludeUHTM and LoadParsedUHTM functions.
	//The third optional argument allows you to remove a previously declared variable.
	// We are introducting field and value in the response
	Response.Subst("CSS", SiteCSSFile);
	Response.Subst("BODYBG", SiteBG);

	Log("Request URI is: " $ Request.URI); // /mainmenu for entry point into Equalizer Web Application
	// Check how we're supposed to handle this query
	switch (Mid(Request.URI, 1))
	{
		case "":
		case RootFrame:
				QueryRootFrame(Request, Response);
			return;
		case HeaderPage:
				QueryHeaderPage(Request, Response);
			return;
		case RestartPage:
				if (!MapIsChanging()) QuerySubmitRestartPage(Request, Response);
			return;
		case SiteCSSFile:
				Response.SendCachedFile( Path $ SkinPath $ "/" $ Mid(Request.URI, 1), "text/css");
			return;
	}

	// If not, allow each query handler a chance to process this query.  Show error message if no query handlers
	// were able to handle the query
	for (i=0; i<QueryHandlers.Length; i++)
	{
		Log("Giving QueryHandlers the request and response " $ QueryHandlers[i].Title $ " and page is " $ QueryHandlers[i].DefaultPage);
		if (QueryHandlers[i].Query(Request, Response))
		{
			return;
		}
	}

	ShowMessage(Response, Error, "Page not found!");
	return;
 }


// Generates the HTML for the top frame, which displays the available areas of webadmin and webadmin skin selector
 function QueryHeaderPage(WebRequest Request, WebResponse Response)
 {
 	local string menu, GroupPage, CurPageTitle;

	Response.Subst("AdminName", CurAdmin.UserName);
	Response.Subst("HeaderColSpan", "2");

	Log("The current admin IS: " $ CurAdmin.UserName);

	Log("Working with Query Handler: " $ QueryHandlerClasses[0]);

	GroupPage = Request.GetVariable("Group", QueryHandlers[0].DefaultPage);

	Log("Setting GroupPage: " $ QueryHandlers[0].DefaultPage);

	// We build a multi-column table for each QueryHandler
	menu = "";
	CurPageTitle = "";

	CurPageTitle = QueryHandlers[0].Title;

/*
	Dis = "";
	if (QueryHandlers[i].NeededPrivs != "" && !CanPerform(QueryHandlers[0].NeededPrivs))
	Dis = "d";

	Response.Subst("MenuLink", RootFrame$"?Group="$QueryHandlers[0].DefaultPage);
	Response.Subst("MenuTitle", QueryHandlers[i].Title);
	menu = menu$WebInclude(HeaderPage$"_item"$Dis);//skinme

	Response.Subst("Location", CurPageTitle);
	Response.Subst("HeaderMenu", menu);

	if ( CanPerform("Xs") )
	{
		Response.Subst("HeaderColSpan", "3");
		Response.Subst("SkinSelect", Select("WebSkin", GenerateSkinSelect()));
		Response.Subst("WebSkinSelect", WebInclude(SkinSelectInclude));
	}
*/

	// Set URIs
	ShowPage(Response, HeaderPage);
}


 function bool ShowFrame(WebResponse Response, string Page)
 {
	Log("Showing Frame:");

	if (CurrentSkin != None && CurrentSkin.HandleHTM(Response, Page))
		return true;

	Response.IncludeUHTM( Path $ SkinPath $ "/" $ Page $ htm);
	return true;
 }

function bool ShowPage(WebResponse Response, string Page)
{
	Log("Showing Page");

	if (CurrentSkin != None && CurrentSkin.HandleHTM(Response, Page))
	{
		Response.ClearSubst();
		return true;
	}
	Response.IncludeUHTM( Path $ SkinPath $ "/" $ Page $ htm);
	Response.ClearSubst();
	return true;
}

// Loads an .inc file into the current WebResponse object
 function string WebInclude(string file)
 {
	local string S;
	if (CurrentSkin != None)
	{
		S = CurrentSkin.HandleWebInclude(Resp, file);
		if (S != "") return S;
	}

	Log("Loading and Returning .inc file");
	return Resp.LoadParsedUHTM(Path $ SkinPath $ "/" $ file $ ".inc");
 }

defaultproperties
{
    //QueryHandlerClasses(0)="Equalizer030158.EQWebAdminQuery"
    DefaultWebSkinClass=Class'EQWebSkin'
    Initialized="%class% Initialized on port %port%"
    AdminRealm="Divine Intervention"
    SiteBG="#243954"
    RootFrame="rootframe"
    HeaderPage="mainmenu"
    MessagePage="message"
    RestartPage="server_restart"
    SiteCSSFile="equalizer.css"
    htm=".htm"
}
