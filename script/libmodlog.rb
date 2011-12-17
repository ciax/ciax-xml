#!/usr/bin/ruby
require 'libmsg'
require 'json'

module ModLog
  def startlog(type,id,ver=0)
    if id && ! ENV.key?('NOLOG')
      @ver=ver.to_i
      @id=id
      @logfile=VarDir+"/"+type+"_#{id}_#{Time.now.year}.log"
      @v.msg{"Init/Start Log '#{type}' (#{id}/Ver.#{@ver})"}
    end
    self
  end

  def stoplog
    @logfile=nil
    self
  end

  def append(str,*cid)
    if @logfile
      tag=([@id,@ver]+cid).compact.join(':')
      open(@logfile,'a') {|f|
        f.puts [Msg.now,tag,str].join("\t")
      }
    end
    self
  end
end
