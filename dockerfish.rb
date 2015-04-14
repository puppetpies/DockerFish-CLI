#!/usr/bin/ruby

########################################################################
#                                                                      #
# Author: Brian Hood                                                   #
# Description: DockerFish Automation                                   #
# Version: v0.1                                                        #
#                                                                      #
########################################################################

require "net/http"
require "uri"
require "json"
require "pp"
require "readline"
require 'getoptlong'

BOOKMARKSFILE = ".bookmarks"
VERSION = 0.1
  
=begin

  Bri's TODO list
  
    TODO: Add Export image
    TODO: Fix multiple container start
    TODO: Add Pull of image from Repository
    TODO: Download progress bar for images
    TODO: Refactor code duplication / case statement
    TODO: Websocket attach with Eventmachine / Readline
  
=end

trap("INT") {
  puts "\nSee you soon !"
  exit
}

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--url', '-u', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--bookmarks', '-b', GetoptLong::NO_ARGUMENT ]
)

def bookmarks(file)
  puts "\e[1;32mBookmarks\e[0m\ "
  puts "\e[1;32m=========\e[0m\ "
  puts "" 
  def read(file)
    b = 1
    @bookmarks = Array.new
    File.open("#{file}", 'r') {|n|
      n.each_line {|l|
        puts "\e[1;36m#{b})\e[0m\ #{l}"
        @bookmarks[b] = l.split(" ")[1]
        b = b + 1
      }
    }
  end
  if File.exists?("#{file}") 
    read(file)
  else
    # Add Localhost to your favourites as an example
    File.open("#{file}", 'w') {|n|
      n.puts("localhost http://localhost:2375")
    }
    read(file)
  end
  while buf4 = Readline.readline("\e[1;33m\Enter Bookmark>\e[0m\ ", true)
    puts @bookmarks[buf4.to_i]
    @bookmarkhost = @bookmarks[buf4.to_i]
    break
  end
end

opts.each do |opt, arg|
  case opt
    when '--help'
      helper = "\e[1;34mWelcome to DockerFish Version #{VERSION}\e[0m\ \n"
      helper << "\e[1;34m=================================\e[0m\ "
      helper << %q[

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
   
    ]
      puts helper
      exit
    when '--bookmarks'
      bookmarks("#{BOOKMARKSFILE}")
    when '--url'
      @dockerurl = arg
  end
end

class Integer

  def to_filesize
    conv = [ 'B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB' ];
    scale = 1024;

    ndx=1
    if( self < 2*(scale**ndx)  ) then
      return "#{(size)}#{conv[ndx-1]}"
    end
    size=self.to_f
    [2,3,4,5,6,7].each do |ndx|
      if( size < 2*(scale**ndx)  ) then
        return "#{'%.3f' % (size/(scale**(ndx-1)))}#{conv[ndx-1]}"
      end
    end
    ndx=7
    return "#{'%.3f' % (size/(scale**(ndx-1)))}#{conv[ndx-1]}"  
  end
  
end

class DockerFish
  
  attr_accessor :baseurl
  
  def initialize
    @baseurl = "http://localhost:2375"
    banner
  end
  
  def banner
    puts "Welcome to DockerFish Version #{VERSION}"
    puts "---------------------------------"
    puts "Interactive CLI Docker Interface"
    print "\[\e[1;31m\]               |
                 |
                ,|.
               ,\|/.
             ,' .V. `.
            / .     . \
           /_`       '_\
          ,' .:     ;, `.
          |@)|  . .  |(@|
     ,-._ `._';  .  :`_,' _,-.
    '--  `-\ /,-===-.\ /-'  --`
   (----  _|  ||___||  |_  ----)
    `._,-'  \  `-.-'  /  `-._,'
             `-.___,-' ap\[\e[0m\]\n"
    puts ""
    puts "TIPS: Please note ContainerId's / Names are interchangeable"
    puts "You can also use short ContainerId's as long as there is a unique match"
    puts "Start with Docker API Enabled: /usr/bin/docker --api-enable-cors=true -H tcp://127.0.0.1:2375 -H unix:///var/run/docker.sock -d"
    puts "--help # For more information"
    puts "\n"
    puts "Enjoy!"
    puts "\n"
    puts "Coded by Brian Hood"
  end
  
  def apiget(url)
    uri = URI.parse("#{url}")
    puts "Request URI: #{url}"
    http = Net::HTTP.new(uri.host, uri.port)
    begin
      response = http.request(Net::HTTP::Get.new(uri.request_uri))  
    rescue
      puts "Error retrieving data"
    end
  end
  
  def apipost(url, body="")
    uri = URI.parse("#{url}")
    puts "Request URI: #{url}"
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_content_type("application/json")
    begin
      request.body = body unless body.empty?
      response = http.request(request)
    rescue
      puts "Error posting data"
    end
  end
  
  def apidelete(url)
    uri = URI.parse("#{url}")
    http = Net::HTTP.new(uri.host, uri.port)
    begin
      response = http.request(Net::HTTP::Delete.new(uri.request_uri))
    rescue
      puts "Error posting data"
    end
  end
  
  def chooser(opts)
    @url = "#{@baseurl}#{opts}"
  end
  
  def apicall(action)
    
    case action
    when action = "images"
      response = apiget("#{@url}")
      begin
        j = JSON.parse(response.body)
      rescue JSON::ParserError
        puts "Could not read JSON data"
      end
      puts "\e[1;30mList of Docker Images\e[0m\ "
      puts "\e[1;30m=====================\e[0m\ "
      puts ""
      0.upto(j.length - 1) {|n|
        j[n].each {|s|
          case s[0]
          when "Created"
            ftime = Time.at(s[1]).to_s
            ctime = ftime[0..18]
            created = "#{s[0]}: #{ctime} "
          when "Id"
            parentid = "#{s[0]}: #{s[1]} "
            imageid = parentid[0..21]
          when "RepoTags"
            repotags = "#{s[0]}: #{s[1]} ".gsub("RepoTags", "Image")
          when "Size"
            num = s[1].to_i.to_filesize
            size = "#{s[0]}: #{num} "
          when "VirtualSize"
            num = s[1].to_i.to_filesize
            virtualsize = "#{s[0]}: #{num} "
          end
          print "#{created} #{imageid} #{repotags} #{size} #{virtualsize}"
        }
        print "\n"
      }
    when action = "containers"
      response = apiget("#{@url}")
      begin
        j = JSON.parse(response.body)
      rescue JSON::ParserError
        puts "Could not read JSON data"
      end
      puts "\e[1;30mList of Docker Containers\e[0m\ "
      puts "\e[1;30m=========================\e[0m\ "
      puts ""
      #puts j.length
      0.upto(j.length - 1) {|n|
        j[n].each {|s|
         case s[0]
         when "Command"
           cmd = "#{s[0]}: #{s[1]}".strip
         when "Id"
           id = "#{s[0]}: #{s[1]} "
           cointainerid = id[0..15].gsub("Id", "ContainerId").strip
         when "Image"
           image = "#{s[0]}: #{s[1]}"
         when "Names"
           names = "#{s[0]}: #{s[1]}".strip
         when "Status"
           status = "#{s[0]}: #{s[1]}"
         when "Created"
           ftime = Time.at(s[1]).to_s
           ctime = ftime[0..18]
           created = "#{s[0]}: #{ctime} ".strip
         end
         print "#{names} #{cointainerid} #{image} #{cmd} #{status}".gsub("   Command:", "Command:")
         #pp s
        }
        print "\n"
      }
      #pp j
    when action = "start"
      response = apipost("#{@url}")
      if response.code == "204"
        puts "\e[1;30mStart Successfull\e[0m\ "
      elsif response.code == "304"
        puts "\e[1;30mContainer already started\e[0m\ "
      elsif response.code == "404"
        puts "\e[1;30mNo such container\e[0m\ "
      elsif response.code == "500"
        puts "\e[1;30mServer error\e[0m\ "
      end
    when action = "pause"
      response = apipost("#{@url}")
      if response.code == "204"
        puts "\e[1;30mPaused Successfull\e[0m\ "
      elsif response.code == "404"
        puts "\e[1;30mNo such container\e[0m\ "
      elsif response.code == "500"
        puts "\e[1;30mServer error\e[0m\ "
      end
    when action = "unpause"
      response = apipost("#{@url}")
      if response.code == "204"
        puts "\e[1;30mResumed Successfull\e[0m\ "
      elsif response.code == "404"
        puts "\e[1;30mNo such container\e[0m\ "
      elsif response.code == "500"
        puts "\e[1;30mServer error\e[0m\ "
      end
    when action = "rename"
      response = apipost("#{@url}")
      if response.code == "204"
        puts "\e[1;30mRenamed Successfully\e[0m\ "
      elsif response.code == "404"
        puts "\e[1;30mNo such container\e[0m\ "
      elsif response.code == "409"
        puts "\e[1;30mName conflict with another container\e[0m\ "
      elsif response.code == "500"
        puts "\e[1;30mServer error\e[0m\ "
      end
    when action = "stop"
      response = apipost("#{@url}")
      if response.code == "204"
        puts "\e[1;30mStopped Successfully\e[0m\ "
      elsif response.code == "304"
        puts "\e[1;30mContainer already stopped\e[0m\ "
      elsif response.code == "404"
        puts "\e[1;30mNo such container\e[0m\ "
      elsif response.code == "500"
        puts "\e[1;30mServer error\e[0m\ "
      end
    when action = "inspect"
      response = apiget("#{@url}")
      begin
        j = JSON.parse(response.body)
      rescue JSON::ParserError
        puts "Could not read JSON data"
      end
      pp j
    when action = "remove"
      response = apidelete("#{@url}")
      if response.code == "204"
        puts "\e[1;30mRemoved Successfully\e[0m\ "
      elsif response.code == "400"
        puts "\e[1;30mBad parameter\e[0m\ "
      elsif response.code == "404"
        puts "\e[1;30mNo such container\e[0m\ "
      elsif response.code == "500"
        puts "\e[1;30mServer error\e[0m\ "
      end
    when action = "imageremove"
      response = apidelete("#{@url}")
      if response.code == "200"
        puts "\e[1;30mRemoved Successfully\e[0m\ "
      elsif response.code == "404"
        puts "\e[1;30mNo such image\e[0m\ "
      elsif response.code == "409"
        puts "\e[1;30mConflict removing image\e[0m\ "
      elsif response.code == "500"
        puts "\e[1;30mServer error\e[0m\ "
      end
    when action = "imagecommit"
      response = apipost("#{@url}")
      if response.code == "201"
        puts "\e[1;30mImage Commit Successfull\e[0m\ "
      elsif response.code == "404"
        puts "\e[1;30mNo such container\e[0m\ "
      elsif response.code == "500"
        puts "\e[1;30mServer error\e[0m\ "
      end
    when action = "create"
      body = %q[{
     "Hostname":"",
     "User":"",
     "Memory":0,
     "MemorySwap":0,
     "CpuShares":0,
     "AttachStdin":true,
     "AttachStdout":true,
     "AttachStderr":true,
     "PortSpecs":null,
     "Tty":true,
     "OpenStdin":true,
     "StdinOnce":true,
     "Env":null,
     "Cmd":[
             "/bin/bash"
     ],
     "Dns":null,
     "Image":"##image##",
     "VolumesFrom":"",
     "WorkingDir":"",
     "HostConfig": {
       "NetworkMode": "bridge",
       "Devices": []
     }
}]
      body.gsub!("##image##", @image)
      puts body
      response = apipost("#{@url}?name=#{@name}", body)
      if response.code == "201"
        puts "\e[1;30mContainer Creation Successfull\e[0m\ "
        j = JSON.parse(response.body)
        0.upto(j.length - 1) {|n|
          j[n].each {|s|
            puts "#{s[0]}: #{s[1]}"
          }
          print "\n"
        }
      elsif response.code == "404"
        puts "\e[1;30mNo such container\e[0m\ "
      elsif response.code == "406"
        puts "\e[1;30mImposible to attach\e[0m\ "
      elsif response.code == "500"
        puts "\e[1;30mServer error\e[0m\ "
      end
    when action = "imagehistory"
      response = apiget("#{@url}")
      begin
        j = JSON.parse(response.body)
      rescue JSON::ParserError
        puts "Could not read JSON data"
      end
      puts "\e[1;30mContainer history\e[0m\ "
      puts "\e[1;30m=================\e[0m\ "
      puts ""
      #puts j.length
      0.upto(j.length - 1) {|n|
        j[n].each {|s|
         case s[0]
         when "Id"
           id = "#{s[0]}: #{s[1]} "
           cointainerid = id[0..15].strip
         when "Created"
           ftime = Time.at(s[1]).to_s
           ctime = ftime[0..18]
           created = "#{s[0]}: #{ctime} ".strip
         when "CreatedBy"
           createdby = "#{s[0]}: #{s[1]}"
         end
         print "#{id} #{created} #{createdby}"
         #pp s
        }
        print "\n"
      }
      if response.code == "404"
        puts "\e[1;30mNo such image\e[0m\ "
      elsif response.code == "500"
        puts "\e[1;30mServer error\e[0m\ "
      end
    when action = "containerprocs"
      response = apiget("#{@url}")
      begin
        j = JSON.parse(response.body)
      rescue JSON::ParserError
        puts "Could not read JSON data"
      end
      pp j
    when action = "search"
      response = apiget("#{@url}")
      begin
        j = JSON.parse(response.body)
      rescue JSON::ParserError
        puts "Could not read JSON data"
      end
      puts "\e[1;30mSearch Results\e[0m\ "
      puts "\e[1;30m==============\e[0m\ "
      puts ""
      #puts j.length
      0.upto(j.length - 1) {|n|
        j[n].each {|s|
         case s[0]
         when "description"
           description = "#{s[0]}: #{s[1]} "
         when "is_offical"
           offical = "#{s[0]}: #{s[1]} "
         when "is_automated"
           automated = "#{s[0]}: #{s[1]}"
         when "name"
           name = "#{s[0]}: #{s[1]}"
         when "star_count"
           starcount = "#{s[0]}: #{s[1]}"
         end
         print "#{name} #{offical} #{automated} #{starcount} #{description}"
         #pp s
        }
        print "\n"
      }
      if response.code == "500"
        puts "\e[1;30mServer error\e[0m\ "
      end
    when action = "menu"
      while buf = Readline.readline("\e[1;32m\DockerFish>\e[0m\ ", true)
        begin
          puts "\n"
          puts "\e[1;38m|Our items in the boat yard|\e[0m\ \n"
          puts "\e[1;38m\\==========================/\e[0m\ "
          puts "\n"
          puts "\e[1;36m1)\e[0m\ List Images"
          puts "\e[1;36m2)\e[0m\ List Containers"
          puts "\e[1;36m3)\e[0m\ Start/Restart Container"
          puts "\e[1;36m4)\e[0m\ Stop Container"
          puts "\e[1;36m5)\e[0m\ Rename Container"
          puts "\e[1;36m6)\e[0m\ Create Container from Image"
          puts "\e[1;36m7)\e[0m\ Remove Container"
          puts "\e[1;36m8)\e[0m\ Inspect Container"
          puts "\e[1;36m9)\e[0m\ View Image History"
          puts "\e[1;36m10)\e[0m\ Search for Images"
          puts "\e[1;36m11)\e[0m\ List Container processes"
          puts "\e[1;36m12)\e[0m\ Remove Image"
          puts "\e[1;36m13)\e[0m\ Pause container"
          puts "\e[1;36m14)\e[0m\ Resume container"
          puts "\e[1;36m15)\e[0m\ Create a new image from a container's changes"
          puts ""
          puts "m: This menu"
          puts "b: Bookmarks"
          puts "q: Exit Dockerfish\n"
          puts "\n"
          case buf
          when "1"
            chooser("/images/json?all=0")
            puts "#{@url}"
            apicall("images")
          when "2"
            chooser("/containers/json?all=1")
            puts "#{@url}"
            apicall("containers")
          when "3"
            while buf2 = Readline.readline("\e[1;33m\Enter Container to Start>\e[0m\ ", true)
              puts "\e[1;30mStarting Container #{buf2}\e[0m\ "
              chooser("/containers/#{buf2}/restart")
              puts "#{@url}"
              apicall("start")
              break
            end
          when "4"
            while buf2 = Readline.readline("\e[1;33m\Enter Container to Stop>\e[0m\ ", true)
              puts "\e[1;30mStopping Container #{buf2}\e[0m\ "
              chooser("/containers/#{buf2}/stop")
              puts "#{@url}"
              apicall("stop")
              break
            end
          when "5"
            while buf2 = Readline.readline("\e[1;33m\Enter Container To Rename>\e[0m\ ", true)
              while buf3 = Readline.readline("\e[1;33m\Enter new name>\e[0m\ ", true)
                chooser("/containers/#{buf2}/rename?name=#{buf3}")
                break
              end
              puts "#{@url}"
              apicall("rename")
              break
            end
          when "6"
            while buf2 = Readline.readline("\e[1;33m\Enter Image to use>\e[0m\ ", true)
              @image = buf2
              puts "Example: name or name1,name2,name3"
              while buf3 = Readline.readline("\e[1;33m\Enter Container name(s)>\e[0m\ ", true)
                if buf3.match(",") == nil
                  chooser("/containers/create")
                  @name = buf3
                  apicall("create")
                else
                  puts "Creating multiple containers..."
                  con = buf3.split(",")
                  0.upto(con.length - 1) {|l|
                    chooser("/containers/create")
                    @name = con[l]
                    puts con[l]
                    apicall("create")
                  }
                end
                break
              end
              break
            end
          when "7"
            while buf2 = Readline.readline("\e[1;33m\Enter Container to Remove>\e[0m\ ", true)
              chooser("/containers/#{buf2}")
              puts "#{@url}"
              apicall("remove")
              break                
            end
          when "8"
            while buf2 = Readline.readline("\e[1;33m\Enter Container to Inspect>\e[0m\ ", true)
              chooser("/containers/#{buf2}/json")
              puts "#{@url}"
              apicall("inspect")
              break
            end
          when "9"
            while buf2 = Readline.readline("\e[1;33m\View history of image>\e[0m\ ", true)
              chooser("/images/#{buf2}/history")
              puts "#{@url}"
              apicall("imagehistory")
              break
            end
          when "10"
            while buf2 = Readline.readline("\e[1;33m\Search for images>\e[0m\ ", true)
              chooser("/images/search?term=#{buf2}")
              puts "#{@url}"
              apicall("search")
              break
            end
          when "11"
            while buf2 = Readline.readline("\e[1;33m\Enter Container to query>\e[0m\ ", true)
              chooser("/containers/#{buf2}/top")
              puts "#{@url}"
              apicall("containerprocs")
              break
            end
          when "12"
            while buf2 = Readline.readline("\e[1;33m\Enter Image to remove>\e[0m\ ", true)
              chooser("/images/#{buf2}")
              puts "#{@url}"
              apicall("imageremove")
              break
            end
          when "13"
            while buf2 = Readline.readline("\e[1;33m\Pause Container name / id>\e[0m\ ", true)
              chooser("/containers/#{buf2}/pause")
              puts "#{@url}"
              apicall("pause")
              break
            end
          when "14"
            while buf2 = Readline.readline("\e[1;33m\Resume Container name / id>\e[0m\ ", true)
              chooser("/containers/#{buf2}/unpause")
              puts "#{@url}"
              apicall("pause")
              break
            end
          when "15"
            while buf2 = Readline.readline("\e[1;33m\Enter Container to Image>\e[0m\ ", true)
              while buf3 = Readline.readline("\e[1;33m\Enter your commit comment important>\e[0m\ ", true)
                commentenc = URI.encode(buf3)
                break
              end
              while buf4 = Readline.readline("\e[1;33m\Enter your Repository name>\e[0m\ ", true)
                chooser("/commit?container=#{buf2}&comment=#{commentenc}&repo=#{buf4}")
                break
              end
              puts "#{@url}"
              apicall("imagecommit")
              break
            end
          when "m"
            apicall("menu")
          #when "b"
          #  ret = bookmarks("#{BOOKMARKSFILE}")
          #  @baseurl = ret
          #  instance_variable_set("@url", ret)
          when "q"
            exit
          when "f"
            banner
          end
        rescue NoMethodError
        end
      end
    end
  end
end

# Instantiate DockerFish instance
t = DockerFish.new
if defined? @dockerurl; t.baseurl = @dockerurl; end
if defined? @bookmarkhost; t.baseurl = @bookmarkhost; end
puts "BaseURL: #{t.baseurl}"
t.apicall("menu")
