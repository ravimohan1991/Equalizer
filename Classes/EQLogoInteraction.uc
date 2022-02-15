/*
 *   --------------------------
 *  |  EQLogoInteraction.uc
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
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
//
// Displays a logo for players connecting.
// Modified by Michael "_Lynx" Sokolkov <aryss.skahara@gmail.com>
// - removed hard-coded reference to UT2003Fonts.exe
//=============================================================================


class EQLogoInteraction extends Interaction
    dependson(EQLogo);


#exec texture Import File=Textures\thequalizer.pcx Name=theequalizer MIPS=OFF
#exec AUDIO IMPORT FILE="Sounds\sawc.wav" NAME="SawIntro"

//=============================================================================
// Constants
//=============================================================================

const STY_Alpha = 5;


//=============================================================================
// Variables
//=============================================================================

var EQLogo     ServerLogo;
var Material   LogoMaterial;
var TexRotator RotatingLogoMaterial;
var Sound      FadeInSound;
var sound      DisplaySound;
var Sound      FadeOutSound;
var float      StartupTime;

var bool bDisplayingLogo;
var bool bFadingIn, bDisplaying, bFadingOut;
var config EQLogo.EFadeTransition TestTransition;


//=============================================================================
// Remove
//
// Unregisters the interaction.
//=============================================================================

 function Remove()
 {
	if(RotatingLogoMaterial != None)
	{
		RotatingLogoMaterial.Material = None;
		RotatingLogoMaterial.FallbackMaterial = None;
		ViewportOwner.Actor.Level.ObjectPool.FreeObject(RotatingLogoMaterial);
		RotatingLogoMaterial = None;
	}
	LogoMaterial = None;
	ServerLogo = None;
	Master.RemoveInteraction(Self);
 }


//=============================================================================
// NotifyLevelChange
//
// Removes the interaction on level change.
//=============================================================================

 event NotifyLevelChange()
 {
	Remove();
 }


//=============================================================================
// PostRender
//
// Draws the logo.
//=============================================================================

 event PostRender(Canvas C)
 {
	local float AlphaFadeIn;
	local float AlphaFadeOut;
	local float X, Y, W, H;

	if(ServerLogo == None || ServerLogo.RLogoResources.Logo == "")
	{
		return;
	}

	if(LogoMaterial == None && ServerLogo.RLogoResources.Logo != "")
	{
		LogoMaterial = Material(DynamicLoadObject(ServerLogo.RLogoResources.Logo, class'Material'));
		if(LogoMaterial == None)
		{
			Remove();
			return;
		}
		if(ServerLogo.RLogoTexCoords.W == 0)
		{
			if(Texture(LogoMaterial) != None)
			{
				ServerLogo.RLogoTexCoords.W = Texture(LogoMaterial).USize;
			}
			else
			{
				ServerLogo.RLogoTexCoords.W = LogoMaterial.MaterialUSize();
			}
		}

		if(ServerLogo.RLogoTexCoords.H == 0)
		{
			if(Texture(LogoMaterial) != None)
			{
				ServerLogo.RLogoTexCoords.H = Texture(LogoMaterial).VSize;
			}
			else
			{
				ServerLogo.RLogoTexCoords.H = LogoMaterial.MaterialVSize();
			}
		}

		if(ServerLogo.RLogoRotationRate != 0)
		{
			RotatingLogoMaterial = TexRotator(ViewportOwner.Actor.Level.ObjectPool.AllocateObject(class'TexRotator'));
			if(RotatingLogoMaterial != None)
			{
				RotatingLogoMaterial.Material = LogoMaterial;
				RotatingLogoMaterial.FallbackMaterial = LogoMaterial;
				RotatingLogoMaterial.TexRotationType = TR_ConstantlyRotating;
				RotatingLogoMaterial.Rotation.Yaw = ServerLogo.RLogoRotationRate;
				RotatingLogoMaterial.UOffset = float(ServerLogo.RLogoTexCoords.W) * 0.5;
				RotatingLogoMaterial.VOffset = float(ServerLogo.RLogoTexCoords.H) * 0.5;
				RotatingLogoMaterial.TexCoordCount = TCN_2DCoords;
				RotatingLogoMaterial.TexCoordProjected = False;
				LogoMaterial = RotatingLogoMaterial;
			}
		}

		if(ServerLogo.RLogoResources.FadeInSound != "")
		{
			FadeInSound = Sound(DynamicLoadObject(ServerLogo.RLogoResources.FadeInSound, class'Sound', True));
			if(ServerLogo.RAnnouncerSounds)
			{
				FadeInSound = ViewportOwner.Actor.CustomizeAnnouncer(FadeInSound);
			}
		}

		if(ServerLogo.RLogoResources.DisplaySound != "")
		{
			DisplaySound = Sound(DynamicLoadObject(ServerLogo.RLogoResources.DisplaySound, class'Sound', True));
			if(ServerLogo.RAnnouncerSounds)
			{
				DisplaySound = ViewportOwner.Actor.CustomizeAnnouncer(DisplaySound);
			}
		}

		if(ServerLogo.RLogoResources.FadeOutSound != "")
		{
			FadeOutSound = Sound(DynamicLoadObject(ServerLogo.RLogoResources.FadeOutSound, class'Sound', True));
			if(ServerLogo.RAnnouncerSounds)
			{
				FadeOutSound = ViewportOwner.Actor.CustomizeAnnouncer(FadeOutSound);
			}
		}

		return;
	}

	if(TestTransition != FT_None)
	{
		TransitionsTest(C);
		return;
	}

	if(StartupTime == 0 || !bDisplayingLogo)
	{
		StartupTime = ServerLogo.Level.TimeSeconds;
		//log(ServerLogo.Level.TimeSeconds@"Start rendering server logo");
	}

	AlphaFadeIn = FClamp(ServerLogo.Level.TimeSeconds - StartupTime,
		0, ServerLogo.RFadeInDuration) / ServerLogo.RFadeInDuration;
	AlphaFadeOut = FClamp(ServerLogo.Level.TimeSeconds - (StartupTime
		+ ServerLogo.RFadeInDuration + ServerLogo.RDisplayDuration),
		0, ServerLogo.RFadeOutDuration) / ServerLogo.RFadeOutDuration;

	C.Reset();
	C.Style = STY_Alpha;
	C.DrawColor = ServerLogo.RLogoColor;

	if(AlphaFadeIn < 1.0)
	{
		bDisplayingLogo = True;
		if(!bFadingIn)
		{
			bFadingIn = True;
			if(FadeInSound != None)
			{
				ViewportOwner.Actor.ClientPlaySound(FadeInSound);
			}
		}

		C.DrawColor.A = FadeIn(AlphaFadeIn, 0, ServerLogo.RLogoColor.A, ServerLogo.RFadeInAlphaTransition);
		X = FadeIn(AlphaFadeIn, ServerLogo.RStartPos.X, ServerLogo.RPos.X, ServerLogo.RFadeInPosXTransition);
		Y = FadeIn(AlphaFadeIn, ServerLogo.RStartPos.Y, ServerLogo.RPos.Y, ServerLogo.RFadeInPosYTransition);
		W = FadeIn(AlphaFadeIn, ServerLogo.RStartScale.X, ServerLogo.RScale.X, ServerLogo.RFadeInScaleTransition);
		H = FadeIn(AlphaFadeIn, ServerLogo.RStartScale.Y, ServerLogo.RScale.Y, ServerLogo.RFadeInScaleTransition);
	}
	else if(AlphaFadeOut == 0)
	{
		bDisplayingLogo = True;
		if ( !bDisplaying )
		{
			bDisplaying = True;
			if(DisplaySound != None)
			{
			ViewportOwner.Actor.ClientPlaySound(DisplaySound);
			}
		}

		C.DrawColor.A = ServerLogo.RLogoColor.A;
		X = ServerLogo.RPos.X;
		Y = ServerLogo.RPos.Y;
		W = ServerLogo.RScale.X;
		H = ServerLogo.RScale.Y;
	}
	else if(AlphaFadeOut < 1.0)
	{
		bDisplayingLogo = True;
		if(!bFadingOut)
		{
			bFadingOut = True;
			if(FadeOutSound != None)
			ViewportOwner.Actor.ClientPlaySound(FadeOutSound);
		}

		C.DrawColor.A = FadeOut(AlphaFadeOut, ServerLogo.RLogoColor.A, 0, ServerLogo.RFadeOutAlphaTransition);
		X = FadeOut(AlphaFadeOut, ServerLogo.RPos.X, ServerLogo.REndPos.X, ServerLogo.RFadeOutPosXTransition);
		Y = FadeOut(AlphaFadeOut, ServerLogo.RPos.Y, ServerLogo.REndPos.Y, ServerLogo.RFadeOutPosYTransition);
		W = FadeOut(AlphaFadeOut, ServerLogo.RScale.X, ServerLogo.REndScale.X, ServerLogo.RFadeOutScaleTransition);
		H = FadeOut(AlphaFadeOut, ServerLogo.RScale.Y, ServerLogo.REndScale.Y, ServerLogo.RFadeOutScaleTransition);
	}
	else
	{
		//log(ServerLogo.Level.TimeSeconds@"Fade Out Done");
		//ViewportOwner.Actor.ClientMessage("Fade Out Done");
		Remove();
		return;
	}

	//log(ServerLogo.Level.TimeSeconds@X@Y@W@H);

	DrawScreenTexture(C, LogoMaterial, X, Y,
		W * ServerLogo.RLogoTexCoords.W, H * ServerLogo.RLogoTexCoords.H,
		ServerLogo.RLogoTexCoords, ServerLogo.RDrawPivot);
}


//=============================================================================
// DrawScreenTexture
//
// Draws a material at the specified screen location.
//=============================================================================

 function DrawScreenTexture(Canvas C, Material M, float X, float Y, float W, float H,
	EQLogo.TTexRegion R, EDrawPivot Pivot)
{
	local float XL, YL;
	local string PoweredText;

	X *= C.SizeX;
	Y *= C.SizeY;

	W *= C.SizeX  / 1024.0;
	H *= C.SizeY / 768.0;

	switch (Pivot)
		{
		case DP_UpperLeft:
			break;
		case DP_UpperMiddle:
				X -= W * 0.5;
			break;
		case DP_UpperRight:
				X -= W;
			break;
		case DP_MiddleRight:
				X -= W;
				Y -= H * 0.5;
			break;
		case DP_LowerRight:
				X -= W;
				Y -= H;
			break;
		case DP_LowerMiddle:
				X -= W * 0.5;
				Y -= H;
			break;
		case DP_LowerLeft:
				Y -= H;
			break;
		case DP_MiddleLeft:
				Y -= H * 0.5;
			break;
		case DP_MiddleMiddle:
				X -= W * 0.5;
				Y -= H * 0.5;
			break;
	}

	//log("Drawn"@X@Y@W@H);

	C.SetPos(X, Y);
	C.DrawTileClipped(M, W, H, R.X, R.Y, R.W, R.H);

	PoweredText = "Equalizer"@class'Equalizer'.default.Version;
	C.Font = GetSmallFontFor(C.ClipX, 0);
	C.StrLen(PoweredText, XL, YL);
	if(XL > W)
	{
		C.Font = GetSmallFontFor(C.ClipX, 1);
	}
	C.StrLen(PoweredText, XL, YL);
	if(XL > W)
	{
		C.Font = GetSmallFontFor(C.ClipX, 2);
	}
	C.StrLen(PoweredText, XL, YL);
	if(XL > W)
	{
		C.Font = GetSmallFontFor(C.ClipX, 3);
	}
	C.SetPos(C.CurX - W / 2 - XL / 2, C.CurY + H + 0.05 * H);
	C.DrawColor = C.static.MakeColor(255, 255, 255);
	C.DrawText(PoweredText);
}

 function Font GetSmallFontFor(int ScreenWidth, int offset)
 {
	local int i;

	for (i = 0; i < 8-offset; i++){
		if(ViewportOwner.Actor.myHUD.default.FontScreenWidthSmall[i] <= ScreenWidth)
			return ViewportOwner.Actor.myHUD.static.LoadFontStatic(i+offset);
	}
	return ViewportOwner.Actor.myHUD.static.LoadFontStatic(8);
 }


//=============================================================================
// FadeIn
//
// Fades a value between a start value and an end value using the specified
// fading method to apply.
//=============================================================================

 function float FadeIn(float Alpha, float Start, float End, EQLogo.EFadeTransition Method)
 {
	switch (Method)
	{
		Case FT_None:
			return End;
		Case FT_Linear:
			return Lerp(Alpha, Start, End);
		Case FT_Square:
			return Lerp(Square(Alpha), Start, End);
		Case FT_Sqrt:
			return Lerp(Sqrt(Alpha), Start, End);
		Case FT_ReverseSquare:
			return Lerp(1-Square(1-Alpha), Start, End);
		Case FT_ReverseSqrt:
			return Lerp(1-Sqrt(1-Alpha), Start, End);
		Case FT_Sin:
			return Lerp(0.5 - 0.5 * Cos(Alpha * Pi), Start, End);
		Case FT_Smooth:
			return Smerp(Alpha, Start, End);
		Case FT_SquareSmooth:
			return Smerp(Square(Alpha), Start, End);
		Case FT_SqrtSmooth:
			return Smerp(Sqrt(Alpha), Start, End);
		Case FT_ReverseSquareSmooth:
			return Smerp(1-Square(1-Alpha), Start, End);
		Case FT_ReverseSqrtSmooth:
			return Smerp(1-Sqrt(1-Alpha), Start, End);
		Case FT_SinSmooth:
			return Smerp(0.5 - 0.5 * Cos(Alpha * Pi), Start, End);
	}
 }


//=============================================================================
// FadeOut
//
// Like FadeIn, but reversed direction.
//=============================================================================

 function float FadeOut(float Alpha, float Start, float End, EQLogo.EFadeTransition Method)
 {
	if(Method == FT_None)
	{
		return Start;
	}
	else
	{
		return FadeIn(Alpha, Start, End, Method);
	}
 }


//=============================================================================
// TransitionsTest
//
// Draws patterns of all transitions and saves them as screenshots.
//=============================================================================

 function TransitionsTest(Canvas C)
 {
	local float x, y;

	C.Reset();
	C.Style = STY_Alpha;
	C.DrawColor.R = 255;
	C.DrawColor.G = 255;
	C.DrawColor.B = 255;
	C.DrawColor.A = 255;
	C.SetPos(0,0);
	C.DrawTile(Texture'WhiteTexture', C.SizeX, C.SizeY, 0, 0, Texture'WhiteTexture'.USize, Texture'WhiteTexture'.VSize);

	C.DrawColor.A = 32;
	for(x = C.OrgX; x < C.SizeX; x += 0.1)
	{
		y = FadeIn(x / C.SizeX, C.OrgY, C.SizeY-1, TestTransition);
		C.SetPos(x,y);
		C.DrawTile(Texture'BlackTexture', 1, 1, 0, 0, Texture'BlackTexture'.USize, Texture'BlackTexture'.VSize);
	}

	C.DrawColor.R = 0;
	C.DrawColor.G = 0;
	C.DrawColor.B = 0;
	C.DrawColor.A = 255;
	C.Font = ViewportOwner.Actor.myHUD.GetConsoleFont(C);
	C.DrawScreenText(string(GetEnum(enum'EFadeTransition', TestTransition)), 0.02, 0.98, DP_LowerLeft);

	ConsoleCommand("shot");
	switch (TestTransition)
	{
		case FT_Linear:
				TestTransition = FT_Square;
			break;
		case FT_Square:
				TestTransition = FT_Sqrt;
			break;
		case FT_Sqrt:
				TestTransition = FT_ReverseSquare;
			break;
		case FT_ReverseSquare:
				TestTransition = FT_ReverseSqrt;
			break;
		case FT_ReverseSqrt:
				TestTransition = FT_Sin;
			break;
		case FT_Sin:
				TestTransition = FT_Smooth;
			break;
		case FT_Smooth:
				TestTransition = FT_SquareSmooth;
			break;
		case FT_SquareSmooth:
				TestTransition = FT_SqrtSmooth;
			break;
		case FT_SqrtSmooth:
				TestTransition = FT_ReverseSquareSmooth;
			break;
		case FT_ReverseSquareSmooth:
				TestTransition = FT_ReverseSqrtSmooth;
			break;
		case FT_ReverseSqrtSmooth:
				TestTransition = FT_SinSmooth;
			break;
		case FT_SinSmooth:
			TestTransition = FT_None;
	}
 }

//=============================================================================
// Default Properties
//=============================================================================

 defaultproperties
 {
    // RotatingLogoMaterial=TexRotator'ServerLogoInteraction.LogoRotator'
    bVisible=True
 }
