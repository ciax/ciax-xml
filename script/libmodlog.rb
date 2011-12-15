#!/usr/bin/ruby
require 'libmsg'
require 'json'

module ModLog
  def startlog(type,id,ver=0)
    if id && ! ENV.key?('NOLOG')
      @ver=ver.to_i
      @logfile=VarDir+"/"+type+"_#{id}_#{Time.now.year}.log"
      @v.msg{"Init/Start Log '#{type}' (#{id}/Ver.#{@ver})"}
    end
    self
  end

  def stoplog
    @logfile=nil
    self
  end

  def append(data,title=nil,time=nil)
    time||=Msg.now
    if @logfile
      id=["##@ver",title].compact.join(':')
      open(@logfile,'a') {|f|
        f.puts [time,id,JSON.dump(data)].join("\t")
      }
    end
    [data,time]
  end
end
