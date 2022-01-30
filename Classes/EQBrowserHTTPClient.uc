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
 * This class has been ripped directly from UT99 uscript package
 * to add the HTTP channel for secure communication with webserver.
 *
 * @since 0.2.0
 */

class EQBrowserHTTPClient extends BufferedTCPLink;

var IpAddr      ServerIpAddr;
var string      ServerAddress;
var string      ServerURI;
var int         ServerPort;
var int         CurrentState;
var int         ErrorCode;
var bool        bClosed;

var globalconfig string ProxyServerAddress;
var globalconfig int    ProxyServerPort;

const Connecting        = 0;
const WaitingForHeader  = 1;
const ReceivingHeader   = 2;
const ReceivingData     = 3;
const HadError          = 4;

 function PostBeginPlay()
 {
	Super.PostBeginPlay();
	ServerIpAddr.Addr = 0;
	Disable('Tick');
 }

 function Browse(string InAddress, string InURI, optional int InPort, optional int InTimeout)
 {
	CurrentState = Connecting;
	
	ServerAddress = InAddress;
	ServerURI = InURI;
	if(InPort == 0)
		ServerPort = 80;
	else
		ServerPort = InPort;
	
	if(InTimeout > 0 )
		SetTimer(InTimeout, False);
	
	ResetBuffer();
	
	if(ProxyServerAddress != "")
	{
		ServerIpAddr.Port = ProxyServerPort;
		if(ServerIpAddr.Addr == 0)
			Resolve(ProxyServerAddress);
		else
			DoBind();
	}
	else
	{
		ServerIpAddr.Port = ServerPort;
		if(ServerIpAddr.Addr == 0)
			Resolve(ServerAddress);
		else
			DoBind();
	}
 }

 function Resolved(IpAddr Addr)
 {
	// Set the address
	ServerIpAddr.Addr = Addr.Addr;
	
	if(ServerIpAddr.Addr == 0)
	{
		Log("UBrowserHTTPClient: Invalid server address", 'Equalizer_TC_alpha1');
		SetError(-1);
		return;
	}

	DoBind();
 }

 function DoBind()
 {
	if(BindPort() == 0)
	{
		Log("UBrowserHTTPLink: Error binding local port.", 'Equalizer_TC_alpha1');
		SetError(-2);
		return;
	}
	
	Open(ServerIpAddr);
	bClosed = False;
 }

 event Timer()
 {
	SetError(-3);
 }

 event Opened()
 {
	Enable('Tick');
	if(ProxyServerAddress != "")
		SendBufferedData("GET http://"$ServerAddress$":"$string(ServerPort)$ServerURI$" HTTP/1.1"$CR$LF);
	else
		SendBufferedData("GET "$ServerURI$" HTTP/1.1"$CR$LF);
	SendBufferedData("User-Agent: Unreal"$CR$LF);
	SendBufferedData("Connection: close"$CR$LF);
	SendBufferedData("Host: "$ServerAddress$":"$ServerPort$CR$LF$CR$LF);
	
	CurrentState = WaitingForHeader;
 }

 function SetError(int Code)
 {
	Disable('Tick');
	SetTimer(0, False);
	ResetBuffer();
	
	CurrentState = HadError;
	ErrorCode = Code;
	
	if(!IsConnected() || !Close())
		HTTPError(ErrorCode);
 }

 event Closed()
 {
	bClosed = True;
 }
 
 function HTTPReceivedData(string Data)
 {
 }
 
 function HTTPError(int Code)
 {
 }

 event Tick(float DeltaTime)
 {
	local string Line;
	local bool bGotData;
	local int NextState;
	local int i;
	local int Result;
	
	Super.Tick(DeltaTime);
	DoBufferQueueIO();
	
	do
	{
		NextState = CurrentState;
		switch(CurrentState)
		{
		case WaitingForHeader:
				bGotData = ReadBufferedLine(Line);
				if(bGotData)
				{
					i = InStr(Line, " ");
					Result = Int(Mid(Line, i+1));
					if(Result != 200)
					{
						SetError(Result);
						return;
					}
					
					NextState = ReceivingHeader;
				}
			break;
		case ReceivingHeader:
				bGotData = ReadBufferedLine(Line);
				if(bGotData)
				{
					if(Line == "")
						NextState = ReceivingData;
				}
			break;
		case ReceivingData:
				bGotData = False;
			break;
		default:
				bGotData = False;
			break;
		}
		CurrentState = NextState;
	} until(!bGotData);
	
	if(bClosed)
	{
		Disable('Tick');
		if(CurrentState == ReceivingData)
			HTTPReceivedData(InputBuffer);
		
		if(CurrentState == HadError)
			HTTPError(ErrorCode);
	}
 }

defaultproperties
{
}
