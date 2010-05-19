#!/usr/bin/ruby
require "json"
require "libverbose"
class IoFile
  include JSON
  VarDir="#{ENV['HOME']}/.var"
  JsonDir="/var/www/json"

  def initialize(type)
    @type=type
    @v=Verbose.new('FILE')
    @logfile=@type+Time.now.strftime("%y%m%d")
  end
  
  def save_stat(stat)
    open(VarDir+"/#{@type}.mar",'w') {|f|
      @v.msg "Status Saving for [#{@type}]"
      f << Marshal.dump(stat)
    }
    stat
  end
  
  def load_stat
    @v.msg("Status Loading for [#{@type}]")
    stat=Marshal.load(IO.read(VarDir+"/#{@type}.mar"))
    raise "No status in File" unless stat
    @v.msg(stat.inspect)
    stat
  end
  
  def save_json(stat)
    open(JsonDir+"/#{@type}.json",'w') {|f|
      @v.msg "JSON Status Saving for [#{@type}]"
      f << JSON.dump(stat)
    }
    stat
  end
  
  def load_json
    @v.msg("JSON Status Loading for [#{@type}]")
    stat=JSON.load(IO.read(JsonDir+"/#{@type}.json"))
    raise "No status in File" unless stat
    @v.msg(stat.inspect)
    stat
  end
  
  def save_frame(cmd,frame)
    open(VarDir+"/#{@type}_#{cmd}.bin",'w') {|f|
      @v.msg "Frame Saving for [#{@type}_#{cmd}]"
      f << frame
    }
    frame
  end

  def load_frame(cmd)
    @v.msg "Raw Status Loading for [#{@type}_#{cmd}]"
    frame=IO.read(VarDir+"/#{@type}_#{cmd}.bin")
    raise "No frame in File" unless frame
    @v.msg(frame.dump)
    frame
  end 
  
  def log_frame(cmd,frame,time=Time.now)
    time="%.3f" % time.to_f
    save_frame(cmd,frame)
    open(VarDir+"/#{@logfile}.log",'a') {|f|
      @v.msg "Frame Logging for [#{@type}_#{cmd}]"
      f << time+' '+cmd+' '+frame.dump+"\n"
    }
    frame
  end

end

