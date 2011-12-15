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

  def append(data,id=nil,time=nil)
    time||=Msg.now
    if @logfile
      tag=["##@ver",id].flatten(1).compact.join(':')
      case data
      when Enumerable
        str=JSON.dump(data)
      else
        str=data.dump
      end
      open(@logfile,'a') {|f|
        f.puts [time,tag,str].join("\t")
      }
    end
    [data,time]
  end
end
