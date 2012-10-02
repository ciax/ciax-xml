#!/usr/bin/ruby
require 'libmsg'
require 'json'

# Should be extend (not include)
module Logging
  extend Msg::Ver
  def self.extended(obj)
    init_ver('Logging/%s',6,obj)
  end

  # append() uses param str or @proc generated data
  def init(type,id,ver=0)
    if id && ! ENV.key?('NOLOG')
      @ver=ver.to_i
      @id=id
      @loghead=VarDir+"/"+type+"_#{id}"
      Logging.msg{"Init/Logging '#{type}' (#{id}/Ver.#{@ver})"}
      @proc=defined?(yield) ? proc{yield} : proc{''}
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
  # ida should be Array
  def append(ida,str=nil)
    Msg.type?(ida,Array)
    time=Msg.now
    if @logging
      str||=@proc.call
      case str
      when Enumerable
        str=JSON.dump(str)
      when String
        str=encode(str)
      end
      tag=([@id,@ver]+ida).compact.join(':')
      open(logfile,'a') {|f|
        f.puts [time,tag,str].compact.join("\t")
      }
      Logging.msg{"Done [#{tag}]"}
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
