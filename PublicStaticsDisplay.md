# Web UI
In order to introduce relevant transparancy of the stored statistics, we provide a public, PHP based, web UI. It is 
simple and clear enough to serve the purpose and provide the satisfaction. 

![Alt Text](/Misc/PublicStatsDisplay.png)

## Installation
- Extract the ```WebScripts/StatisticsUI/LargeNUI.php``` to some place on WebServer.
- Modify the following fields
  ```
  $servername = "localhost"; // usually you don't need to change this
  $username = "cowboy"; // the name of the user of a database
  $password = "BWxFPjNuIYBPxxg0"; // the password for accessing the database
  $database = "CowboysTestDatabase"; // the database itself, which you want to display publically
  ```
- And that is it! Access the the web page from your favorite browser, like so
  ``` 
  http://www.somename.com/StatisticsUI/LargeNUI.php
  ```  

