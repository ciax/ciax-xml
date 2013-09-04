#!/usr/bin/ruby
require 'libmsg'
require 'json'
require "monitor"

# Capable of wider application than SqLog
module CIAX
  class Logging
    include MonitorMixin
    include Msg
    def initialize(type,id,ver=0)
      @ver_color=6
      @type=type?(type,String)
      type?(id,String)
      ver=ver.to_i
      @header={'time' => UnixTime.now,'id' => id,'ver' => ver}
      @loghead=VarDir+"/"+type+"_#{id}"
      verbose("Logging","Init/Logging '#{type}' (#{id}/Ver.#{ver})")
      super()
    end

    # Return UnixTime
    def append(data)
      time=@header['time']=UnixTime.now
      unless ENV.key?('NOLOG')
        str=JSON.dump(@header.merge(data))
        synchronize{
          open(logfile,'a') {|f|
            f.puts str
          }
        }
        verbose("Logging","#{@type}/Appended #{str.size} byte")
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
      @loghead+"_#{UnixTime.now.year}.log"
    end

    def encode(str)
      #str.dump
      [str].pack("m").split("\n").join('')
    end
  end
end
