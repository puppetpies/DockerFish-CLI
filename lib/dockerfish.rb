#!/usr/bin/ruby

########################################################################
#                                                                      #
# Author: Brian Hood                                                   #
# Description: DockerFish Automation                                   #
#                                                                      #
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

class DockerFish
  
  attr_accessor :baseurl
  attr_writer :image, :hostname
  
  def initialize(splash)
    @baseurl = "http://localhost:2375"
    @containerjson = "container.json"
    if splash == true; banner; end
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
    puts "Add a symlink ln -s /home/brian/Projects/DockerFish/dockerfish.rb /usr/bin/dockerfish\n\n"
    puts "Container Config file: #{Dir.home}/.dockerfish/#{@containerjson}\n\n"
    if File.exists?("#{Dir.home}/.dockerfish/#{@containerjson}") == false
      puts "\e[1;31m\WARNING: \e[0m\ \e[1;32m\ To Create Containers \e[1;33m\ mkdir #{Dir.home}/.dockerfish\e[0m\ \e[1;32m\ and copy the provided container.json into it !!!\e[0m\ \n\n"
    end
    puts "--help # For more information"
    puts "\n"
    puts "Enjoy!"
    puts "\n"
    puts "Coded by Brian Hood"
    version
  end
  
  def apiget(url)
    uri = URI.parse("#{url}")
    #puts "Request URI: #{url}"
    http = Net::HTTP.new(uri.host, uri.port)
    begin
      response = http.request(Net::HTTP::Get.new(uri.request_uri))
      puts response.body
    rescue
      puts "Error retrieving data"
    end
  end
  
  def apipost(url, body="")
    uri = URI.parse("#{url}")
    #puts "Request URI: #{url}"
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
  
  def version
    @url = "#{@baseurl}/version"
    uri = URI.parse("#{@url}")
    begin
      response = apiget("#{@url}")
      puts "Server Info:\n\n"
      j = JSON.parse(response.body)
      pp j
    rescue JSON::ParserError, NoMethodError
      puts "Could not read JSON data"
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
      body = String.new
      File.open("#{Dir.home}/.dockerfish/#{@containerjson}", 'r') {|n|
        n.each_line {|l|
          body << l
        }
      }
      body.gsub!("##hostname##", @hostname)
      body.gsub!("##image##", @image)
      puts body
      if !defined? @name; @name = @hostname; end
      response = apipost("#{@url}?name=#{@name}", body)
      if response.code == "201"
        puts "\e[1;30mContainer Creation Successfull\e[0m\ "
        j = JSON.parse(response.body)
        n = 0
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
      puts "\e[1;30mImage history\e[0m\ "
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
           name = "Image: \e[1;36m\ [\"#{s[1]}\"] \e[0m\ "
         when "star_count"
           starcount = "Star rating: #{s[1]}"
         end
         print "#{name} #{starcount}".lstrip
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
            #puts "#{@url}"
            apicall("images")
          when "2"
            chooser("/containers/json?all=1")
            #puts "#{@url}"
            apicall("containers")
          when "3"
            while buf2 = Readline.readline("\e[1;33m\Enter Container to Start>\e[0m\ ", true)
              puts "\e[1;30mStarting Container #{buf2}\e[0m\ "
              chooser("/containers/#{buf2}/restart")
              #puts "#{@url}"
              apicall("start")
              break
            end
          when "4"
            while buf2 = Readline.readline("\e[1;33m\Enter Container to Stop>\e[0m\ ", true)
              puts "\e[1;30mStopping Container #{buf2}\e[0m\ "
              chooser("/containers/#{buf2}/stop")
              #puts "#{@url}"
              apicall("stop")
              break
            end
          when "5"
            while buf2 = Readline.readline("\e[1;33m\Enter Container To Rename>\e[0m\ ", true)
              while buf3 = Readline.readline("\e[1;33m\Enter new name>\e[0m\ ", true)
                chooser("/containers/#{buf2}/rename?name=#{buf3}")
                break
              end
              #puts "#{@url}"
              apicall("rename")
              break
            end
          when "6"
            while buf2 = Readline.readline("\e[1;33m\Enter Image to use>\e[0m\ ", true)
              @image = buf2
              while buf3 = Readline.readline("\e[1;33m\Enter Container name(s)>\e[0m\ ", true)
                chooser("/containers/create")
                @hostname = buf3
                apicall("create")
                break
              end
              break
            end
          when "7"
            while buf2 = Readline.readline("\e[1;33m\Enter Container to Remove>\e[0m\ ", true)
              chooser("/containers/#{buf2}")
              #puts "#{@url}"
              apicall("remove")
              break                
            end
          when "8"
            while buf2 = Readline.readline("\e[1;33m\Enter Container to Inspect>\e[0m\ ", true)
              chooser("/containers/#{buf2}/json")
              #puts "#{@url}"
              apicall("inspect")
              break
            end
          when "9"
            while buf2 = Readline.readline("\e[1;33m\View history of image>\e[0m\ ", true)
              chooser("/images/#{buf2}/history")
              #puts "#{@url}"
              apicall("imagehistory")
              break
            end
          when "10"
            while buf2 = Readline.readline("\e[1;33m\Search for images>\e[0m\ ", true)
              chooser("/images/search?term=#{buf2}")
              #puts "#{@url}"
              apicall("search")
              break
            end
          when "11"
            while buf2 = Readline.readline("\e[1;33m\Enter Container to query>\e[0m\ ", true)
              chooser("/containers/#{buf2}/top")
              #puts "#{@url}"
              apicall("containerprocs")
              break
            end
          when "12"
            while buf2 = Readline.readline("\e[1;33m\Enter Image to remove>\e[0m\ ", true)
              chooser("/images/#{buf2}")
              #puts "#{@url}"
              apicall("imageremove")
              break
            end
          when "13"
            while buf2 = Readline.readline("\e[1;33m\Pause Container name / id>\e[0m\ ", true)
              chooser("/containers/#{buf2}/pause")
              #puts "#{@url}"
              apicall("pause")
              break
            end
          when "14"
            while buf2 = Readline.readline("\e[1;33m\Resume Container name / id>\e[0m\ ", true)
              chooser("/containers/#{buf2}/unpause")
              #puts "#{@url}"
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
              #puts "#{@url}"
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

class FishControl

  def initialize
    @apiobj = DockerFish.new(false)
    @containerjson = "container.json"
  end
  
  def containerctl(container, action, image="<none>:<none>")
    if image != "<none>:<none>"
      @apiobj.image = image
      puts "My Image: #{image}"
    end
    container.split(",").each {|n|
      @apiobj.hostname = "#{n}"
      puts "Container: #{n} Action: #{action}"
      if action == "create"
        @apiobj.chooser("/containers/#{action}")
      else
        @apiobj.chooser("/containers/#{n}/#{action}")
      end
      @apiobj.apicall("#{action}")  
    }
    exit
  end
  
end
