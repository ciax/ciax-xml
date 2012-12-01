#!/usr/bin/ruby
require 'libmsg'
require 'json'

# Should be extend (not include)
module Logging
  extend Msg::Ver
  def self.extended(obj)
    init_ver('Logging/%s',6,obj)
  end

  # append() uses @proc(Hash) generated data
  def ext_logging(type,id,ver=0,&p)
    Msg.type?(type,String)
    Msg.type?(id,String)
    ver=ver.to_i
    @header={:id => id,:ver => ver}
    @loghead=VarDir+"/"+type+"_#{id}"
    Logging.msg{"Init/Logging '#{type}' (#{id}/Ver.#{ver})"}
    @proc=p
    self
  end

  # Return Time
  # ida should be Array
  def append
    time=Msg.now
    unless ENV.key?('NOLOG')
      str=JSON.dump(@header.merge(@proc.call))
      open(logfile,'a') {|f|
        f.puts [time,str].compact.join("\t")
      }
      Logging.msg{"Appended [#{str}]"}
    end
    time
  end

  def self.set_logline(str)
    ary=str.split("\t")
    h={:time => ary.shift}
    h[:id],h[:ver],dir,*h[:cmd]=ary.shift.split(':')
    abort("Logline:Line is not rcv") unless /rcv/ === dir
    h[:data]=decode(ary.shift)
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

class ExHash
  def ext_logging(type,id,ver=0,&p)
    extend(Logging).ext_logging(type,id,ver,&p)
    self
  end
end
