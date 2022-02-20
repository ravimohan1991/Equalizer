# Requirements
- GameServer
    - [UT2004](https://www.gog.com/en/game/unreal_tournament_2004_ece) (Windows or Linux)
- WebServer
    - Relevant WebSpace
    - [PHPMyAdmin](https://www.phpmyadmin.net/)
- (Optional) [FileZilla](https://filezilla-project.org/) (an FTP client)

# Installing
Follow these steps to generate a working instance of Equalizer on the server:


- Extract the ```.zip``` file to some safe place. Look out for ```System``` folder and drop its contents (UPackage, meta, and ini files) in the game server's ```System``` folder.

- Open the ```Server.ini``` file (containing all the information about game server configuration and operations) and add the following line in the section ```[Engine.GameEngine]```
  like so
  ```
  ServerPackages=Equalizer<UPackageIS>
  ```
  where ```<UPackageIS>``` is the identifier string of Equalizer package (basically ```Version + BuildNumber```) that you extracted from the ```.zip``` file. For instance, "020158" in the UPackage "Equalizer020158.u". For rest of the part of this document, we shall assume the ```Version = 020``` and ```BuildNumber = 158```
  <ins>Note</ins>: In this case the line to be added is
  ```
  ServerPackages=Equalizer020158
  ```
  without "<>".
  
- Now you need to tell game server to load relevant class ```Equalizer```. It is usually done in two ways  
  
    - ## Equalizer for Mutator
      To load relevant class ```Equalizer``` as a mutator by the following command line (in the case we are considering)
      ```
      ucc server CTF-Magma?Game=XGame.XCTFGame?Mutator=Equalizer020158.Equalizer
      ```
      If done the right way, Equalizer shall be loaded at the start of every map! Consult [UnrealAdmin](https://wiki.unrealadmin.org/Commandline_Parameters_(UT2004)). 
      <ins>Note</ins>: You may wanna use the relevant identifier string (IS) whilst writing the command.
   
   
    - ## Equalizer for ServerActor (needs testing)
      In this context, we add the following line in the section ```Engine.GameEngine``` like so
      ```
      ServerActors=Equalizer020158.Equalizer
      ```
   <ins>Please note you need to follow **either** *Equalizer for Mutator* **or** *Equalizer for ServerActor*</ins>. Also note that the oder of loading the Equalizer class matters. 
   Based on the dependencies (for instance [UniqueIdentifier](https://github.com/ravimohan1991/Equalizer/blob/miasmactivity/UniqueIdentifier.md)) you may need to deduce the right order. Please
   *always ask* if you got no clue about what to do! Or, the very least, admit it! Moving on...
 
 - Look out for ```WebScripts``` folder and extract the contents (the ```EqualizerBE```) in the relevant directory on WebServer. You may wanna use some super duper FTP client,
   for instance FileZilla.
   
 - Now you wanna modify the following fields in the script ```main.php``` like so
   ```
   $servername = "localhost"; // Usually you don't wanna modify this
   $username = "cowboy"; // The name of the database user
   $password = "BWxFPjNuIYBPxxg0"; // The password of the user
   $database = "CowboysTestDatabase"; // The name of the database
   ```
 - Once that is done, open the ```Equalizer.ini``` file and modify (if needed) the following fields
   ```
   QueryServerHost="localhost"
   QueryServerFilePath="/EqualizerBE/eqquery.php" // the relative path of the eqquery.php file
   QueryServerPort=80
   ```
   For the description of other fields, refer the [ReadMe](https://github.com/ravimohan1991/Equalizer/blob/miasmactivity/README.md)'s configuration section!
   
 - Finally, if you want to have web access to Equalizer, modify the section ```[UWeb.WebServer]``` in ```UT2004.ini``` like so
   ```
   Applications[0]=xWebAdmin.UTServerAdmin // Make sure this order is maintained with UTServerAdmin at top
   ApplicationPaths[0]=/ServerAdmin
   Applications[1]=xWebAdmin.UTImageServer // UTImage server is essential for displaying the relevant images
   ApplicationPaths[1]=/images
   Applications[2]=Equalizer020158.EQWebAdminServer // Finally we provide room to our own EQWebAdmin
   ApplicationPaths[2]=/Equalizer
   bEnabled=True // Should be set to true
   ListenPort=8080 // Generally you won't need to change this until there is some faliure to bind at the default port
   ```
   Make sure to extract the contents of ```Equalizer-0.2.0/Web``` to ```/Web``` of UT2k4 installation.
