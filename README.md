# DockerFish-CLI
Dockerfish command line tool with readline support

All you need is Ruby installed and i'm not using any Gems

[brian@orville DockerFish]$ ./dockerfish.rb -h
Welcome to DockerFish Version 0.1 
================================= 

-h, --help:
   show help

-u, -url Docker Host URL:
   Note: Docker Host must of API Enabled to connect
   Example: http://10.0.0.1:2375
   
   Defaults to http://localhost:2375
   
-b, --bookmarks
   Create .bookmarks file format
   
   Example:
   
   localhost http://127.0.0.1:2375
   remoteserver http://10.0.2.15:2375
   
[brian@orville DockerFish]$ ./dockerfish.rb -b    
Bookmarks 
========= 

1) localhost http://127.0.0.1:2375
2) wifi http://10.130.2.128:2375
3) test http://0.0.0.0:2375
Enter Bookmark> 

