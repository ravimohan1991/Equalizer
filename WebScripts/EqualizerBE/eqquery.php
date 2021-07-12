<?php
header("Content-Type: text/html; charset=utf-8");

/******************************************************************************
 *	
 ******************************************************************************/

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
    storeInformation();
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

function storeInformation()
{
    global $infoArray;
      
    foreach ($infoArray as $info)
    {
        global $tableName;

        $infoColumns = explode(':', $info);
        
        $bFirstElement = true;
        $index = 0;
        
        foreach($infoColumns as $columns)
        {
            if($bFirstElement)
            {
                $tableName = $columns;
                createTable($tableName);
                $bFirstElement = false;
            }
            else 
            {   
                $columnArrayData[$index++] = $columns;
            }
        }
        
        fillTable($tableName, $columnArrayData);
    }
}
?>
