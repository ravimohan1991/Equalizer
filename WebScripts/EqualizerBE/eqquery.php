<?php
header("Content-Type: text/html; charset=utf-8");

/******************************************************************************
 *	
 ******************************************************************************/

error_reporting(E_ALL);
include_once 'connect.php';

$tableName;

/**
 * Get an array of information out of query string to process.
 *
 * @token arpan The identifier for information meant to be submitted
 * @since 0.1.0
 */

if(isset($_GET['arpan']))
{
    $infoArray = explode(',', $_GET['arpan']);
}
else
{
    echo "Nothing to process";
    die();
}

createDatabaseConnection();

/**
 * Spit out the useful information as per the made query.
 *
 * @since 0.1.0
 */
$index = 0;
$bFirstElement = true;
foreach ($infoArray as $info)
{
    global $tableName;
    
    if($bFirstElement)
    {
        $tableName = $info;
        createTable($tableName);
        $bFirstElement = false;
    }
    else 
    {
        fillTable($tableName, $info, $index++);
        echo "," . $info;
    }
}

?>
