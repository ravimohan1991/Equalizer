/*
 *   --------------------------
 *  |  EQWebSkin.uc
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
 * @author The_Cowboy
 * @since 0.3.0
 */

class EQWebSkin extends WebSkin;

 function Init(UTServerAdmin WebAdmin)
 {
 	WebAdmin.SkinPath = "";
 	WebAdmin.SiteBG = DefaultBGColor;
 	WebAdmin.SiteCSSFile = SkinCSS;
 }

defaultproperties
{
    DisplayName="Divine Intervention"
    SkinCSS="equalizer.css"
}
