<?php
/*
 *   --------------------------
 *  |  eqquery.php
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

header("Content-Type: text/html; charset=utf-8");

error_reporting(E_ALL);
include_once 'main.php';

$infoArray;

/**
 * Get an array of information out of query string to process.
 *
 * @token arpan The identifier for information meant to be submitted
 * @since 0.2.0
 */

if(isset($_GET['arpan']))
{
    global $infoArray;
    
    $infoArray = explode(',', $_GET['arpan']);
    createDatabaseConnection();
    createTable("EQPlayerInformation");
    storeModifyInformation();
}
else
{
    echo "Nothing to process";
    die();
}


/**
 * Fill up the database with relevant information
 *
 * The information cipher [TableName] : [EQUniqueIdentifer] : [Captures] ...
 * Note: multiple information can be stored with delimiter "," like information1,information2 ...
 * 
 * @since 0.2.0
 */

function storeModifyInformation()
{
    global $infoArray;
      
    foreach ($infoArray as $info)
    {
        $infoColumns = explode(':', $info);
        
        $bFirstElement = true;
        $index = 0;
        
        foreach($infoColumns as $columns)
        {
            if($bFirstElement)
            {
                $bFirstElement = false;
            }
            else 
            {   
                $columnArrayData[$index++] = $columns;
            }
        }
        
        fillTable($columnArrayData);
    }
}
?>
