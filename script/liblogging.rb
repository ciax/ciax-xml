#!/usr/bin/ruby
require 'libmsg'
require 'json'

module Logging
  def init(type,id,ver=0)
    if id && ! ENV.key?('NOLOG')
      @ver=ver.to_i
      @id=id
      @loghead=VarDir+"/"+type+"_#{id}"
      @v.msg{"Init/Start Log '#{type}' (#{id}/Ver.#{@ver})"}
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
      str=JSON.dump(str) if Enumerable === str
      tag=([@id,@ver]+cid).compact.join(':')
      open(logfile,'a') {|f|
        f.puts [time,tag,str].compact.join("\t")
      }
    end
    time
  end

  private
  def logfile
    @loghead+"_#{Time.now.year}.log"
  end
end
