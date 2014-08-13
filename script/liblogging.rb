#!/usr/bin/ruby
require 'libmsg'
require 'json'
require "thread"

# Capable of wider application than SqLog
module CIAX
  class Logging
    include Msg
    def initialize(type,header)
      @cls_color=1
      @pfx_color=14
      @type=type?(type,String)
      @header=type?(header,Hash)
      id=@header['id']
      ver=@header['ver']
      FileUtils.mkdir_p VarDir
      @loghead=VarDir+"/"+type+"_#{id}"
      verbose("Logging","Init/Logging '#{type}' (#{id}/Ver.#{ver})")
      @queue=Queue.new
      Threadx.new("Logging(#{type}:#{ver})",11){
        loop{
          logary=[]
          begin
            logary << @queue.pop
          end until @queue.empty?
          open(logfile,'a') {|f|
            logary.each{|str|
              f.puts str
              verbose("Logging","#{@type}/Appended #{str.size} byte #{str}")
            }
          }
        }
      }
    end

    # Return UnixTime
    def append(data)
      time=@header['time']=now_msec
      unless ENV.key?('NOLOG')
        str=JSON.dump(@header.merge(data))
        @queue.push str
      end
      time
    end

    #For new format
    def self.set_logline(str)
      h=JSON.load(str)
      abort("Logline:Line is not rcv") unless /rcv/ === h['dir']
      if data=h.delete('base64')
        h[:data]=data.unpack("m").first
      end
      h
    end

    private
    def logfile
      @loghead+"_#{Time.now.year}.log"
    end

    def encode(str)
      #str.dump
      [str].pack("m").split("\n").join('')
    end
  end
end
