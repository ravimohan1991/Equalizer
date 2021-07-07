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

 /***/
 var bool bContinueAtClose;

 /***/
 var bool bResolutionRequest;

 /***/
 var bool bReceivedData;


 /***/
 var int Errors;

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
 
 function string SendData(string Information)
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
 
 	AddToQueue(Information);
 	SendQueue();
 
 	return "";
 }
 
 function HTTPReceivedData(string Data)
 {
 	local string result;
 
 	result = ParseString(Data);
 
 	Super.SetTimer(0.0, false); // disable the timeout count
 	bReceivedData = true;
 
 	Log("The data received is " $ Data, 'Equalizer');
 
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
 
 	// sometimes the connection doesn't break immediately, it is probably due to some bug in BrowserHTTPClient, if it happens we have to wait for it inside event Closed() cause we cannot open the same socket if it is already opened
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

 function SendQueue()
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
 
 	Browse(EQMut.ResolvedAddress, EQMut.QueryServerFilePath $ "?ip=" $ QueryString, EQMut.QueryServerPort, EQMut.MaxTimeout);
 }
 
 function AddToQueue(string Data)
 {
 	local int i;
 
 	for(i = 0; i < ArrayCount(QueryQueue); i++)
 	{
 		if(QueryQueue[i] != "")
 			continue;

		QueryQueue[i] = Data;

		if(!bQueryInProgress)
 			SendQueue();
 		break;
 	}
 }
 
 function string ParseString (String Input)
 {
 	local int LCRLF;
 	local string result;
 
 	LCRLF = InStr(Input, CR$LF);
 
 	// No CR or LF in string
 	if (LCRLF == -1)
 		return Input;
 	else
 	{
 		result = Right(Input, len(Input)-LCRLF-2);
 		LCRLF = InStr(result ,CR$LF);
 		result = Left(result, LCRLF);
 		return result;
 	}
 }
 
 defaultproperties
 {
     Tag='EQHTTPClient'
     bHidden=true
 }
