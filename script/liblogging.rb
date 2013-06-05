#!/usr/bin/ruby
require 'libmsg'
require 'json'

# Should be extend (not include)
class Logging
  include Msg::Ver
  def initialize(type,id,ver=0,&p)
    @ver_color=6
    @type=Msg.type?(type,String)
    Msg.type?(id,String)
    ver=ver.to_i
    @header={'time' => UnixTime.now,'id' => id,'ver' => ver}
    @loghead=VarDir+"/"+type+"_#{id}"
    verbose("Logging","Init/Logging '#{type}' (#{id}/Ver.#{ver})")
    @proc=p
    self
  end

  # Return UnixTime
  # append() uses @proc(Hash) generated data
  def append
    time=@header['time']=UnixTime.now
    unless ENV.key?('NOLOG')
      str=JSON.dump(@header.merge(@proc.call))
      open(logfile,'a') {|f|
        f.puts str
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
      h['data']=data.unpack("m").first
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
