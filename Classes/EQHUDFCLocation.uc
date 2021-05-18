/*
 *   --------------------------
 *  |  EQHUDFCLocation.uc
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
 * This Class renders the FlagCarrier location at the top of the Screen,
 *
 * @author The_Cowboy
 * @since 0.1.0
 */

class EQHUDFCLocation extends HudCCaptureTheFlag;

/**
 * The function gets called just at the Client while drawing the CTF HUD.
 *
 * @param Canvas The Canvas on which HUD is drawn
 * @since 0.1.0
 */

simulated function ShowTeamScorePassA(Canvas C)
{
	local CTFBase B;
	local int i;
	local PlayerReplicationInfo LPRI;
	local float XL, YL;

	if ( bShowPoints )
	{
		DrawSpriteWidget (C, TeamScoreBackground[0]);
		DrawSpriteWidget (C, TeamScoreBackground[1]);
		DrawSpriteWidget (C, TeamScoreBackgroundDisc[0]);
		DrawSpriteWidget (C, TeamScoreBackgroundDisc[1]);

		TeamScoreBackground[0].Tints[TeamIndex] = HudColorBlack;
		TeamScoreBackground[0].Tints[TeamIndex].A = 150;
		TeamScoreBackground[1].Tints[TeamIndex] = HudColorBlack;
		TeamScoreBackground[1].Tints[TeamIndex].A = 150;
		
		DrawSpriteWidget (C, NewFlagWidgets[0]);
		DrawSpriteWidget (C, NewFlagWidgets[1]);
		
		NewFlagWidgets[0].Tints[0] = HudColorTeam[0];
		NewFlagWidgets[0].Tints[1] = HudColorTeam[0];
		
		NewFlagWidgets[1].Tints[0] = HudColorTeam[1];
		NewFlagWidgets[1].Tints[1] = HudColorTeam[1];
		
		DrawSpriteWidget (C, VersusSymbol );
	 	DrawNumericWidget (C, ScoreTeam[0], DigitsBig);
		DrawNumericWidget (C, ScoreTeam[1], DigitsBig);

		if ( RedBase == None )
		{
			ForEach DynamicActors(Class'CTFBase', B)
			{
				if ( B.IsA('xRedFlagBase') )
					RedBase = B;
				else
					BlueBase = B;
			}
		}
		if ( RedBase != None )
		{
			C.DrawColor = HudColorRed;
			Draw2DLocationDot(C, RedBase.Location,0.5 - REDtmpPosX*HUDScale, REDtmpPosY*HUDScale, REDtmpScaleX*HUDScale, REDtmpScaleY*HUDScale);
		}
		if ( BlueBase != None )
		{
			C.DrawColor = HudColorBlue;
			Draw2DLocationDot(C, BlueBase.Location,0.5 + BLUEtmpPosX*HUDScale, BLUEtmpPosY*HUDScale, BLUEtmpScaleX*HUDScale, BLUEtmpScaleY*HUDScale);
		}

		if ( PlayerOwner.GameReplicationInfo == None )
			return;

		for (i = 0; i < 2; i++)
		{
			if ( PlayerOwner.GameReplicationInfo.FlagState[i] == EFlagState.FLAG_HeldEnemy )
				DrawSpriteWidget (C, FlagHeldWidgets[i]);
			else if ( PlayerOwner.GameReplicationInfo.FlagState[i] == EFlagState.FLAG_Down )
				DrawSpriteWidget (C, FlagDownWidgets[i]);
		}

		for(i = 0; i < PlayerOwner.GameReplicationInfo.PRIArray.Length; i++)
		{
			if(PlayerOwner.GameReplicationInfo.PRIArray[i].HasFlag != none && PlayerOwner.PlayerReplicationInfo.Team.TeamIndex ==
				PlayerOwner.GameReplicationInfo.PRIArray[i].Team.TeamIndex && PlayerOwner.PlayerReplicationInfo != PlayerOwner.GameReplicationInfo.PRIArray[i])
			{
				LPRI = PlayerOwner.GameReplicationInfo.PRIArray[i];
				C.Font = LoadFontStatic(7);
				C.StrLen("FC:"$LPRI.GetLocationName(), XL, YL);

				if(LPRI.Team.TeamIndex == 0)
				{
					C.DrawColor = WhiteColor;
					C.SetPos(C.ClipX / 2 + C.ClipX * 0.03, C.ClipY * 0.08);
				}
				else
				{
					C.DrawColor = WhiteColor;
					C.SetPos(C.ClipX / 2 - C.ClipX * 0.03 - XL, C.ClipY * 0.08);
				}

				C.DrawText("FC:"$LPRI.GetLocationName());
				break;
			}
		}
	}
 }

defaultproperties
{

}
