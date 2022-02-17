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


// =====================================================================================================================
// =====================================================================================================================
//  Initialization
// =====================================================================================================================
// =====================================================================================================================
event Init()
{
	local UTServerAdmin UTSA;
	local byte index;

    Super.Init();

	for(index = 0; index < 10; index++)
	{
     if(WebServer.ApplicationObjects[index] != none && WebServer.ApplicationObjects[index].IsA('UTServerAdmin'))
     {
         UTSA = UTServerAdmin (WebServer.ApplicationObjects[index]);
         Log("Successfully assigned WebAdmin's AdminSpectator. Judicious eh!", 'Equalizer');
         break;// Assumption: UTServerAdmin be the first in the list of ApplicaitonObjects declaration!
     }
    }

    if(UTSA == none)
    {
     Log("Couldn't find WebAdmin instance of the Game.", 'Equalizer');
     return;
    }

	// won't change as long as the server is up and the map hasnt changed
	LoadQueryHandlers();

	ReplaceText( Initialized, "%class%", string(Class) );
	ReplaceText( Initialized, "%port%", string(WebServer.ListenPort) );
	Log(Initialized,'Equalizer');
}


defaultproperties
{
     QueryHandlerClasses(0)="XWebAdmin.xWebQueryCurrent"
     QueryHandlerClasses(1)="XWebAdmin.xWebQueryDefaults"
     QueryHandlerClasses(2)="XWebAdmin.xWebQueryAdmins"
     Initialized="%class% Initialized on port %port%"
}
