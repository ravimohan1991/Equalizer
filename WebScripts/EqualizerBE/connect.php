<?php
$servername = "localhost";
$username = "cowboy";
$password = "BWxFPjNuIYBPxxg0";
$database = "CowboysTestDatabase";

$conn;
$columnArray[0] = "EQIdentifier";
$columnArray[1] = "Captures";
$columnArray[2] = "TimePlayedMinutes";

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

function createTable($playerinfo)
{
    global $conn, $columnArray;
    global $database;
    $createTableString = "CREATE TABLE `$database`.`$playerinfo` ( `$columnArray[0]` CHAR(80) NULL DEFAULT NULL , `$columnArray[1]` INT NULL DEFAULT NULL , `$columnArray[2]` INT NULL DEFAULT NULL ) ENGINE = InnoDB;";
    $conn->query($createTableString);

    $conn->query("ALTER TABLE `$playerinfo` ADD UNIQUE(`EQIdentifier`);");
}


function fillTable($tableName, $data, $columnIndex)
{
    global $conn, $columnArray;
    $fillColumnsString = "INSERT INTO `$tableName` (`$columnArray[$columnIndex]`) VALUES ('$data')";
    $conn->query($fillColumnsString);
}

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
