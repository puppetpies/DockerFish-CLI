# DockerFish-CLI

[![Gem Version](https://badge.fury.io/rb/dockerfish.svg)](https://badge.fury.io/rb/dockerfish)

Dockerfish command line tool with readline support

All you need is Ruby installed and i'm not using any Gems

Remember ( gem install dockerfish )

![Docker CLI ](https://raw.githubusercontent.com/puppetpies/DockerFish-CLI/master/screenshot.png)

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

dockerfish --start test-01,test-02
dockerfish --stop test-01,test-02

# Create a container
dockerfish --create centos-01 --contimage centos:latest

