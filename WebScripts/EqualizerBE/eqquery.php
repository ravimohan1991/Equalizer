<?php
header("Content-Type: text/html; charset=utf-8");

/******************************************************************************
 *	
 ******************************************************************************/

error_reporting(E_ALL);

/**
 * Get an array of information out of query string to process.
 *
 * @token arpan The identifier for information meant to be submitted
 * @since 0.1.0
 */

if(isset($_GET['arpan']))
{
    $ipArray = explode(',', $_GET['arpan']);
}
else
{
    echo "Nothing to process";
    die();
}


foreach ($ipArray as $ip)
{
    echo $ip . PHP_EOL;
}

?>
