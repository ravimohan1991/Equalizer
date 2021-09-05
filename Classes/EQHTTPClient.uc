/*
 *   ------------------------
 *  | EQBrowserHTTPClient.uc
 *   ------------------------
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
 *
 *
 * @since 0.2.0
 */

class EQHTTPClient extends EQBrowserHTTPClient;

/*
 * Global Variables
 */

 /** The IpToNation Actor reference.*/
 var Equalizer EQMut;

 /** Query in progress logical switch.*/
 var bool bQueryInProgress;

 /** Queue Array of information. */
 var string QueryQueue[64];

 /** Should we continue to send data (one last time?) when the connection is closed or dropped. */
 var bool bContinueAtClose;

 /** Is address resolution in progress? */
 var bool bResolutionRequest;

 /** Just received the latest data. Set to false in the begining of every new query. */
 var bool bReceivedData;

 /** Enumtype stuff for specifying the type of query. */
 const SubmitEQInfo      = 0;
 const QueryEQInfo       = 1;

 function CheckAddresses()
 {
 	if(!bResolutionRequest && EQMut.ResolvedAddress == "")
 	{
 		bResolutionRequest = True;
 		bQueryInProgress = True;

 		Resolve(EQMut.QueryServerHost);
 	}
 }

 event Resolved(IpAddr Addr)
 {
 	if(bResolutionRequest)
 	{
 		EQMut.ResolvedAddress = IpAddrToString(Addr);

 		// strip out port number
 		if (InStr(EQMut.ResolvedAddress, ":") != -1)
 			EQMut.ResolvedAddress = Left(EQMut.ResolvedAddress, InStr(EQMut.resolvedAddress, ":"));

 		EQMut.SaveConfig();

 		bResolutionRequest = False;
 		bQueryInProgress = False;

 		SendQueue();
 	}
 	else
 	{
 		Super.Resolved(Addr);
 	}
 }

 event ResolveFailed()
 {
 	if(bResolutionRequest)
 	{
 		Log("Error while resolving" @ EQMut.QueryServerHost @ "to an IP.", 'Equalizer');
 		Log("If the error continues this could indicate that the operating system is not configured to resolve DNS records.", 'Equalizer');

 		EQMut.RestartHTTPClient();
 	}
 	else
 	{
 		SetTimer(0.0, false);
 		SetError(-4);
 	}
 }

 function string SendData(string Information, int QueryType)
 {
 	local Equalizer Equality;

 	if(EQMut == None)
 	{
 		foreach AllActors(class'Equalizer', Equality)
 		{
 			EQMut = Equality;
 			break;
 		}
 	}

 	AddToQueue(Information, QueryType);
 	SendQueue(QueryType);

 	return "";
 }

 function HTTPReceivedData(string Data)
 {
 	local string Result;

 	Result = ParseString(Data);

 	Super.SetTimer(0.0, false); // disable the timeout count
 	bReceivedData = true;

 	if(Result != "")
 	{
        if(EQMut != none)
        {
         EQMut.GatherAndProcessInformation(Result);
        }
        else
        {
         Log("Received data when EQMut is not aligned. Report to developer", 'Equalizer');
        }
    }

 	bQueryInProgress = False;

 	SendQueue();
 }

 event Opened()
 {
 	Enable('Tick');

 	if(ProxyServerAddress != "")
 	{
 		SendBufferedData("GET http://"$ServerAddress$":"$string(ServerPort)$ServerURI$" HTTP/1.1"$CR$LF);
 	}
 	else
 	{
 		SendBufferedData("GET "$ServerURI$" HTTP/1.1"$CR$LF);
 	}

 	SendBufferedData("Connection: close" $ CR $ LF);
 	SendBufferedData("Host: " $ EQMut.QueryServerHost $ ":" $ EQMut.QueryServerPort $ CR $ LF);
 	SendBufferedData("User-Agent: Mozilla/5.0 (Unreal Tournament)" $ CR $ LF $ CR $ LF);

 	CurrentState = WaitingForHeader;
 }

 function DoBind()
 {
 	if(BindPort() == 0)
 	{
 		SetError(-2);
 		return;
 	}

 	Open(ServerIpAddr);
 	bClosed = False;
 }

 function SetError(int Code)
 {
 	Super.SetError(Code);

 	switch(Code)
 	{
 		case -1:
 			Log("Error in binding the port while connecting to " $ EQMut.QueryServerHost, 'Equalizer');
 			break;
 		case -2:
			Log("Error while resolving the host " $ EQMut.QueryServerHost, 'Equalizer');
			break;
 		case -3:
 			Log(EQMut.QueryServerHost$" timed out after " $ string(EQMut.MaxTimeout)$" seconds", 'Equalizer');
 			break;
 		case -4:
 			Log("Error resolving to the host of the IP for the domain " $ EQMut.QueryServerHost);
 			break;
 		default:
 			Log("Server received HTTP error with code " $ string(Code)$" from " $ EQMut.QueryServerHost);
 	}

 	// sometimes the connection doesn't break immediately, it is probably due to some bug in EQBrowserHTTPClient, if it happens we have to wait for it inside event Closed() cause we cannot open the same socket if it is already opened
 	EQMut.RestartHTTPClient();
 }

 event Closed()
 {
 	Super.Closed();
 	bQueryInProgress = False;

 	if(bContinueAtClose)
 	{
 		bContinueAtClose = False;
 		bQueryInProgress = False;
 		SendQueue();
 	}
 }

 function SendQueue(optional int QueryType)
 {
 	local int i;
 	local string QueryString;

 	CheckAddresses();

 	if(IsConnected())
 	{
 		bContinueAtClose = True;
 	}

 	if(bQueryInProgress || (QueryQueue[0] == ""))
 	{
 		return;
 	}

 	for(i = 0; i< ArrayCount(QueryQueue); i++)
 	{
 		if(QueryQueue[i] == "")
 			continue;

 		if(QueryString == "")
 			QueryString = QueryQueue[i];
 		else
 			QueryString = QueryString$","$QueryQueue[i];

		QueryQueue[i] = "";
 	}

 	if(QueryString == "")
 	{
 		return;
 	}

 	bQueryInProgress = True;
 	bReceivedData = False;

 	switch(QueryType)
 	{
     case SubmitEQInfo:
      Browse(EQMut.ResolvedAddress, EQMut.QueryServerFilePath $ "?arpan=" $ QueryString, EQMut.QueryServerPort, EQMut.MaxTimeout);
      break;

     case QueryEQInfo:
      Browse(EQMut.ResolvedAddress, EQMut.QueryServerFilePath $ "?arzi=" $ QueryString, EQMut.QueryServerPort, EQMut.MaxTimeout);
      break;
    }
 }

 function AddToQueue(string Data, int QueryType)
 {
 	local int i;

 	for(i = 0; i < ArrayCount(QueryQueue); i++)
 	{
 		if(QueryQueue[i] != "")
 			continue;

		QueryQueue[i] = Data;

		if(!bQueryInProgress)
 			SendQueue(QueryType);
 		break;
 	}
 }

 function string ParseString(String GString) // GString means Gyan(Knowledge) String
 {
 	local int PCRLF, PLF;
 	local string result;

 	PCRLF = InStr(GString, CR$LF);
    PLF = InStr(GString, LF);

    if(PCRLF != -1)
    {
        Log("CRLF line break detected. Are you using Windows OS server? Still? Anywho, report this log to the developer", 'Equalizer');
        result = Right(GString, len(GString) - PCRLF - 2);
 		PCRLF =  InStr(result, CR$LF);
 		result = Left(result, PCRLF);
 		return "";
    }
    else if(PLF != -1)
    {
        result = Right(GString, len(GString) - PLF - 1);
 		return result;
    }
    else
    {
 		return GString;
    }
 }

 defaultproperties
 {
     Tag='EQHTTPClient'
     bHidden=true
 }
