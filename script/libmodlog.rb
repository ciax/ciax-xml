#!/usr/bin/ruby
require 'libmsg'
require 'json'

module ModLog
  def startlog(type,id,ver=0)
    if id && ! ENV.key?('NOLOG')
      @ver=ver.to_i
      @id=id
      @loghead=VarDir+"/"+type+"_#{id}"
      @v.msg{"Init/Start Log '#{type}' (#{id}/Ver.#{@ver})"}
    end
    self
  end

  def stoplog
    @loghead=nil
    self
  end

  # Return Time
  def append(str,*cid)
    time=Msg.now
    if @loghead
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
