#!/usr/bin/ruby
require 'libmsg'
require 'json'

# Should be extend (not include)
class Logging
  include Msg::Ver
  def initialize(type,id,ver=0,&p)
    init_ver(self,6)
    @type=Msg.type?(type,String)
    Msg.type?(id,String)
    ver=ver.to_i
    @header={'time' => Sec.now,'id' => id,'ver' => ver}
    @loghead=VarDir+"/"+type+"_#{id}"
    verbose{"Init/Logging '#{type}' (#{id}/Ver.#{ver})"}
    @proc=p
    self
  end

  # Return Sec
  # append() uses @proc(Hash) generated data
  def append
    time=@header['time']=Sec.now
    unless ENV.key?('NOLOG')
      str=JSON.dump(@header.merge(@proc.call))
      open(logfile,'a') {|f|
        f.puts str
      }
      verbose{"#{@type}/Appended #{str.size} byte"}
    end
    time
  end

  #For new format
  def self.set_logline(str)
    h=JSON.load(str)
    abort("Logline:Line is not rcv") unless /rcv/ === h['dir']
    h['data']=decode(h['base64'])
    h['time']=Sec.parse(h['time'])
    h
  end

  def self.decode(data)
    #eval(data)
    data.unpack("m").first
  end

  private
  def logfile
    @loghead+"_#{Sec.now.year}.log"
  end

  def encode(str)
    #str.dump
    [str].pack("m").split("\n").join('')
  end
end
