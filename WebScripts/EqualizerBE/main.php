<?php
/*
 *   --------------------------
 *  |  main.php
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

$servername = "localhost";
$username = "cowboy";
$password = "BWxFPjNuIYBPxxg0";
$database = "CowboysTestDatabase";

$conn;
$tableName;
$columnArray[0] = "EQIdentifier";
$columnArray[1] = "Captures";
$columnArray[2] = "TimePlayedMinutes";
$columnArrayAttributes[0] = "CHAR(80) NULL DEFAULT NULL";
$columnArrayAttributes[1] = "INT NULL DEFAULT NULL";
$columnArrayAttributes[2] = "INT NULL DEFAULT NULL";

/**
 * Here we connect to the relevant database
 *
 * @since 0.2.0
 */

function createDatabaseConnection()
{
    global $servername, $username, $password, $database;
    global $conn;
    // Create connection
    $conn = new mysqli($servername, $username, $password, $database);

    // Check connection
    if ($conn->connect_error) 
    {
      die("Connection failed: " . $conn->connect_error);
    }
    echo "Connected successfully";
}

/**
 * Table creation method with relevant columns corresponding to player statistics.
 * 
 * @token $tName The name of the table
 * @see $columnArray, $columnArrayAttributes
 * @since 0.2.0
 */

function createTable($tName)
{
    global $conn, $tableName, $columnArray, $columnArrayAttributes;
    global $database;
    
    $tableName = $tName;
    
    if(doesItExist($tableName))
    {
        return;
    }
    
    $createTableString = "CREATE TABLE `$database`.`$tableName` (";
    
    $bFirstElement = true;
    $index = 0;
    foreach($columnArray as $column)
    {
        if($bFirstElement)
        {
            $bFirstElement = false;
            $createTableString = $createTableString . " `$column` " . $columnArrayAttributes[$index];
        }
        else 
        {
            $createTableString = $createTableString  . " , " . " `$column` " . $columnArrayAttributes[$index]; 
        }
        
        $index++;
    }
    
    $createTableString = $createTableString . " ) ENGINE = InnoDB;";
    
    $conn->query($createTableString);
    $conn->query("ALTER TABLE `$tableName` ADD UNIQUE(`EQIdentifier`);");
}

/**
 * Discerning the existence of table with particular name
 * 
 * @token $tName The name of the table
 
 * @since 0.2.0
 */

function doesItExist($tName)
{
    global $conn;
    
    $result = $conn->query("SHOW TABLES LIKE '" . $tName . "'");
    
    if($result->num_rows == 1) 
    {
        return true;
    }
    else 
    {
        return false;
    }
}


/**
 * Fillup the table (in form of row) with desired information received from game-server
 * 
 * @token $dataArray Array containing player specific data in some order (of collection?)
 * @see $columnArray
 * @since 0.2.0
 */

function fillTable($dataArray)
{
    global $conn, $tableName, $columnArray;
    $fillColumnsString = "INSERT INTO `$tableName` ( ";
  
    $bFirstElement = true;
    foreach ($columnArray as $column)
    {
        if($bFirstElement)
        {
            $bFirstElement = false;
            $fillColumnsString = $fillColumnsString . "`$column`";
        }
        else
        {
            $fillColumnsString = $fillColumnsString . " , " . "`$column`";
        }
    }
    
    $fillColumnsString = $fillColumnsString . " )  VALUES ( ";
    
    $bFirstElement = true;
    foreach($dataArray as $data)
    {
       if($bFirstElement)
       {
           $bFirstElement = false;
           $fillColumnsString = $fillColumnsString . "'$data'";
       }
       else 
       {
           $fillColumnsString = $fillColumnsString . " , " . "'$data'"; 
       }
    }
    
    $fillColumnsString = $fillColumnsString . " )";
    
    $conn->query($fillColumnsString);
}

/**
 * For debug purposes only
 * 
 * @since 0.2.0
 */

function searchDatabase()
{
    global $conn;
    // Query database
    $result = $conn->query("SELECT * FROM EQPlayerInfo");

    echo $result->num_rows;

    if($result)
        echo "Found something";
    else
        echo "Found nothing";
}
?> 
