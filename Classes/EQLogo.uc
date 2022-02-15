/*
 *   --------------------------
 *  |  EQLogo.uc
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

//=============================================================================
// Ripped from Wrombo's
// ServerLogo
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
//
// Replicated the information for a logo displayed for players connecting.
//=============================================================================


class EQLogo extends ReplicationInfo
    config
    placeable
    hidecategories(Display,Advanced,Sound,Events);


//=============================================================================
// Enums
//=============================================================================

enum EFadeTransition
{
  FT_None,
  FT_Linear,
  FT_Square,
  FT_Sqrt,
  FT_ReverseSquare,
  FT_ReverseSqrt,
  FT_Sin,
  FT_Smooth,
  FT_SquareSmooth,
  FT_SqrtSmooth,
  FT_ReverseSquareSmooth,
  FT_ReverseSqrtSmooth,
  FT_SinSmooth
};


//=============================================================================
// Structs
//=============================================================================

struct TScreenCoords
{
  var() config float X;
  var() config float Y;
};

struct TTexRegion
{
  var() config int X;
  var() config int Y;
  var() config int W;
  var() config int H;
};

// replicated as a struct to make sure everything arrives at the same time
struct TRepResources
{
  var string Logo;
  var string FadeInSound;
  var string DisplaySound;
  var string FadeOutSound;
};


//=============================================================================
// Configuration
//=============================================================================

var(Logo)                  string          Logo;
var(Logo)           config color           LogoColor;
var(Logo)           config TTexRegion      LogoTexCoords;
var(Logo)           config int             StartLogoRotationRate;
var(Logo)           config int             LogoRotationRate;
var(Logo)           config int             EndLogoRotationRate;
var(LogoPosition)   config TScreenCoords   StartPos;
var(LogoPosition)   config TScreenCoords   Pos;
var(LogoPosition)   config TScreenCoords   EndPos;
var(LogoPosition)   config EDrawPivot      DrawPivot;
var(LogoScale)      config TScreenCoords   StartScale;
var(LogoScale)      config TScreenCoords   Scale;
var(LogoScale)      config TScreenCoords   EndScale;
var(LogoSound)      config string          FadeInSound;
var(LogoSound)      config string          DisplaySound;
var(LogoSound)      config string          FadeOutSound;
var(LogoSound)      config bool            AnnouncerSounds;
var(LogoTransition) config float           FadeInDuration;
var(LogoTransition) config float           DisplayDuration;
var(LogoTransition) config float           FadeOutDuration;
var(LogoTransition) config float           InitialDelay;
var(LogoTransition) config EFadeTransition FadeInRotationTransition;
var(LogoTransition) config EFadeTransition FadeOutRotationTransition;
var(LogoTransition) config EFadeTransition FadeInAlphaTransition;
var(LogoTransition) config EFadeTransition FadeOutAlphaTransition;
var(LogoTransition) config EFadeTransition FadeInScaleTransition;
var(LogoTransition) config EFadeTransition FadeOutScaleTransition;
var(LogoTransition) config EFadeTransition FadeInPosXTransition;
var(LogoTransition) config EFadeTransition FadeInPosYTransition;
var(LogoTransition) config EFadeTransition FadeOutPosXTransition;
var(LogoTransition) config EFadeTransition FadeOutPosYTransition;


//=============================================================================
// Variables
//=============================================================================

var float Build;

var TRepResources   RLogoResources;
var color           RLogoColor;
var TTexRegion      RLogoTexCoords;
var int             RStartLogoRotationRate;
var int             RLogoRotationRate;
var int             REndLogoRotationRate;
var TScreenCoords   RStartPos;
var TScreenCoords   RPos;
var TScreenCoords   REndPos;
var TScreenCoords   RStartScale;
var TScreenCoords   RScale;
var TScreenCoords   REndScale;
var EDrawPivot      RDrawPivot;
var float           RFadeInDuration;
var float           RDisplayDuration;
var float           RFadeOutDuration;
var float           RInitialDelay;
var bool            RAnnouncerSounds;
var EFadeTransition RFadeInRotationTransition;
var EFadeTransition RFadeOutRotationTransition;
var EFadeTransition RFadeInScaleTransition;
var EFadeTransition RFadeOutScaleTransition;
var EFadeTransition RFadeInPosXTransition;
var EFadeTransition RFadeInPosYTransition;
var EFadeTransition RFadeOutPosXTransition;
var EFadeTransition RFadeOutPosYTransition;
var EFadeTransition RFadeInAlphaTransition;
var EFadeTransition RFadeOutAlphaTransition;

var float SpawnTime;
var bool bReceivedVars;


//=============================================================================
// Replication
//=============================================================================

replication
{
  reliable if ( Role == ROLE_Authority )
    RLogoResources, RLogoTexCoords, RDrawPivot, RLogoColor, RAnnouncerSounds,
    RStartLogoRotationRate, RLogoRotationRate, REndLogoRotationRate,
    RStartPos, RPos, REndPos, RStartScale, RScale, REndScale,
    RFadeInRotationTransition, RFadeOutRotationTransition,
    RFadeInAlphaTransition, RFadeOutAlphaTransition,
    RFadeInScaleTransition, RFadeOutScaleTransition,
    RFadeInPosXTransition, RFadeOutPosXTransition,
    RFadeInPosYTransition, RFadeOutPosYTransition,
    RFadeInDuration, RDisplayDuration, RFadeOutDuration, RInitialDelay;
}


//=============================================================================
// PostBeginPlay
//
// Replicate all config variables.
//=============================================================================

 simulated function PostBeginPlay()
 {
	Super.PostBeginPlay();

	if(Role == ROLE_Authority)
	{
		SaveConfig();
		if(int(Level.EngineVersion) > 3186)
		{
			UpdatePackageMap();
		}

		Build = class'Equalizer'.default.BuildNumber;
		Logo = "Equalizer" $ class'Equalizer'.default.Version $ class'Equalizer'.default.BuildNumber $ ".theequalizer";
		RLogoResources.Logo = "Equalizer" $ class'Equalizer'.default.Version $ class'Equalizer'.default.BuildNumber $ ".theequalizer";
		RLogoResources.FadeInSound = FadeInSound;
		RLogoResources.DisplaySound = DisplaySound;
		RLogoResources.FadeOutSound = FadeOutSound;
		RAnnouncerSounds = AnnouncerSounds;
		RLogoColor = LogoColor;
		RLogoTexCoords = LogoTexCoords;
		RStartLogoRotationRate = StartLogoRotationRate;
		RLogoRotationRate = LogoRotationRate;
		REndLogoRotationRate = EndLogoRotationRate;
		RDrawPivot = DrawPivot;
		RFadeInRotationTransition = FadeInRotationTransition;
		RFadeOutRotationTransition = FadeOutRotationTransition;
		RFadeInScaleTransition = FadeInScaleTransition;
		RFadeOutScaleTransition = FadeOutScaleTransition;
		RFadeInPosXTransition = FadeInPosXTransition;
		RFadeInPosYTransition = FadeInPosYTransition;
		RFadeOutPosXTransition = FadeOutPosXTransition;
		RFadeOutPosYTransition = FadeOutPosYTransition;
		RFadeInAlphaTransition = FadeInAlphaTransition;
		RFadeOutAlphaTransition = FadeOutAlphaTransition;

		if ( FadeInAlphaTransition > FT_None || FadeInScaleTransition > FT_None
			|| FadeInPosXTransition > FT_None || FadeInPosYTransition > FT_None
			|| FadeInRotationTransition > FT_None )
		{
			RFadeInDuration = FadeInDuration;
		}

		RDisplayDuration = DisplayDuration;

		if ( FadeOutAlphaTransition > FT_None || FadeOutScaleTransition > FT_None
			|| FadeOutPosXTransition > FT_None || FadeOutPosYTransition > FT_None
			|| FadeOutRotationTransition > FT_None )
		{
			RFadeOutDuration = FadeOutDuration;
		}

		RInitialDelay = InitialDelay;
		RStartPos = StartPos;
		RPos = Pos;
		REndPos = EndPos;
		RStartScale = StartScale;
		RScale = Scale;
		REndScale = EndScale;
	}
 }


//=============================================================================
// UpdatePackageMap
//
// Make sure the logo and sound packages are sent to clients.
//=============================================================================

 function UpdatePackageMap()
 {
	local int i;

	AddToPackageMap();
	if(Logo != "")
	{
		i = InStr(Logo, ".");
		if (i > -1 && DynamicLoadObject(Logo, class'Texture', true) != None)
		{
			AddToPackageMap(Left(Logo, i));
			Log("Update package"@Logo@i, 'Equalizer');
		}
	}
	if(FadeInSound != "")
	{
		i = InStr(FadeInSound, ".");
		if(i > -1 && DynamicLoadObject(FadeInSound, class'Sound', true) != None)
		{
			AddToPackageMap(Left(FadeInSound, i));
		}
	}
	if ( DisplaySound != "" )
	{
		i = InStr(DisplaySound, ".");
		if(i > -1 && DynamicLoadObject(DisplaySound, class'Sound', true) != None)
		{
			AddToPackageMap(Left(DisplaySound, i));
		}
	}
	if( FadeOutSound != "" )
	{
		i = InStr(FadeOutSound, ".");
		if(i > -1 && DynamicLoadObject(FadeOutSound, class'Sound', true) != None)
		{
			AddToPackageMap(Left(FadeOutSound, i));
		}
	}
 }


//=============================================================================
// PostNetBeginPlay
//
// Replicate all config variables.
//=============================================================================

 simulated function PostNetBeginPlay()
 {
	bReceivedVars = True;
	Enable('Tick');
 }


//=============================================================================
// Tick
//
// Initialize the Interaction and load the logo texture.
//=============================================================================

 simulated function Tick(float DeltaTime)
 {
	local PlayerController LocalPlayer;
	local Interaction MyInteraction;

	if(!bReceivedVars || Level.NetMode == NM_DedicatedServer)
	{
		Disable('Tick');
		return;
	}
	else if(RLogoResources.Logo == "")
	{
		return;
	}
	else if( SpawnTime == 0.0 )
	{
		SpawnTime = Level.TimeSeconds;
	}

	//log(Level.TimeSeconds@"LevelAction:"@Level.LevelAction);

	if(Level.TimeSeconds - SpawnTime < RInitialDelay)
	{
		return;
	}

	LocalPlayer = Level.GetLocalPlayerController();
	if(LocalPlayer != None)
	{
		MyInteraction = LocalPlayer.Player.InteractionMaster.AddInteraction(string(class'EQLogoInteraction'), LocalPlayer.Player);
	}
	if(EQLogoInteraction(MyInteraction) != None)
	{
		EQLogoInteraction(MyInteraction).ServerLogo = Self;
	}

	//log(Level.TimeSeconds@"Spawned"@MyInteraction@"for"@LocalPlayer);
	Disable('Tick');
}


//=============================================================================
// Default Properties
//=============================================================================

 defaultproperties
 {
    LogoColor=(B=255,G=255,R=255,A=255)
    LogoTexCoords=(X=0,Y=0,W=0,H=0)
    LogoRotationRate=0
    StartPos=(X=0.990000,Y=0.100000)
    pos=(X=0.990000,Y=0.100000)
    EndPos=(X=0.990000,Y=0.100000)
    DrawPivot=DP_MiddleRight
    StartScale=(X=1.000000,Y=1.000000)
    Scale=(X=1.000000,Y=1.000000)
    EndScale=(X=1.000000,Y=1.000000)
    FadeInDuration=1.00000
    DisplayDuration=3.000000
    FadeOutDuration=1.00000
    InitialDelay=0.000000
    DisplaySound="Equalizer.SawIntro"
    AnnouncerSounds=False
    FadeInAlphaTransition=FT_Linear
    FadeOutAlphaTransition=FT_Linear
    FadeInScaleTransition=FT_None
    FadeOutScaleTransition=FT_None
    FadeInPosXTransition=FT_None
    FadeInPosYTransition=FT_None
    FadeOutPosXTransition=FT_None
    FadeOutPosYTransition=FT_None
    StartLogoRotationRate=0
    EndLogoRotationRate=0
    FadeInRotationTransition=FT_None
    FadeOutRotationTransition=FT_None
 }
