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

  def append(data,*cid)
    time||=Msg.now
    if @logfile
      tag=([@id,@ver]+cid).compact.join(':')
      str=ModLog.encode(data)
      open(@logfile,'a') {|f|
        f.puts [time,tag,str].join("\t")
      }
    end
    [data,time]
  end

  def self.encode(data)
    case data
    when Enumerable
      str=JSON.dump(data)
    else
      str=data.dump
    end
    str
  end

  def self.decode(str)
    case str
    when /^(\[.*\]|{.*})$/
      data=JSON.load(str)
    when /".*"/
      data=eval(str)
    else
      data=''
    end
    data
  end

end
