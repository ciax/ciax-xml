#!/usr/bin/ruby
require 'libmsg'
require 'json'
require "thread"

# Capable of wider application than SqLog
module CIAX
  class Logging
    include Msg
    def initialize(type,id,ver=0)
      @ver_color=6
      @type=type?(type,String)
      type?(id,String)
      ver=ver.to_i
      @header={'time' => nowsec,'id' => id,'ver' => ver}
      FileUtils.mkdir_p VarDir
      @loghead=VarDir+"/"+type+"_#{id}"
      verbose("Logging","Init/Logging '#{type}' (#{id}/Ver.#{ver})")
      @queue=Queue.new
      Threadx.new("Logging Thread(#{type}:#{ver})",10){
        loop{
          logary=[]
          begin
            logary << @queue.pop
          end until @queue.empty?
          open(logfile,'a') {|f|
            logary.each{|str|
              f.puts str
              verbose("Logging","#{@type}/Appended #{str.size} byte")
            }
          }
        }
      }
    end

    # Return UnixTime
    def append(data)
      time=@header['time']=nowsec
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
