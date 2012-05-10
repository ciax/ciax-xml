#!/usr/bin/ruby
require 'libmsg'
require 'json'

module Logging
  extend Msg::Ver
  def init(type,id,ver=0)
    Logging.init_ver(self,5)
    if id && ! ENV.key?('NOLOG')
      @ver=ver.to_i
      @id=id
      @loghead=VarDir+"/"+type+"_#{id}"
      Logging.msg{"Init/Logging '#{type}' (#{id}/Ver.#{@ver})"}
      startlog
    end
    self
  end

  def startlog
    @logging=true
    self
  end

  def stoplog
    @logging=false
    self
  end

  # Return Time
  def append(*cid)
    time=Msg.now
    if @logging
      str=yield
      case str
      when Enumerable
        str=JSON.dump(str)
      when String
        str=encode(str)
      end
      tag=([@id,@ver]+cid).compact.join(':')
      open(logfile,'a') {|f|
        f.puts [time,tag,str].compact.join("\t")
      }
      Logging.msg{"Logging Done [#{tag}]"}
    end
    time
  end

  def self.set_logline(str)
    ary=str.split("\t")
    h={:time => ary.shift}
    h[:id],h[:ver],dir,*h[:cmd]=ary.shift.split(':')
    abort("Logline:Not response") unless /rcv/ === dir
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
