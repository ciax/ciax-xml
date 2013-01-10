#!/usr/bin/ruby
require 'libmsg'
require 'json'

# Should be extend (not include)
class Logging
  extend Msg::Ver
  def initialize(type,id,ver=0,&p)
    Logging.init_ver(self,6)
    @type=Msg.type?(type,String)
    Msg.type?(id,String)
    ver=ver.to_i
    @header={'time' => Msg.now,'id' => id,'ver' => ver}
    @loghead=VarDir+"/"+type+"_#{id}"
    Logging.msg{"Init/Logging '#{type}' (#{id}/Ver.#{ver})"}
    @proc=p
    self
  end

  # Return Time
  # append() uses @proc(Hash) generated data
  def append
    time=@header['time']=Msg.now
    unless ENV.key?('NOLOG')
      str=JSON.dump(@header.merge(@proc.call))
      open(logfile,'a') {|f|
        f.puts str
      }
      Logging.msg{"#{@type}/Appended #{str.size} byte"}
    end
    time
  end

  #For new format
  def self.set_logline(str)
    h=JSON.load(str)
    abort("Logline:Line is not rcv") unless /rcv/ === h['dir']
    h['data']=decode(h['data'])
    h
  end

  def self.decode(data)
    #eval(data)
    data.unpack("m").first
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
