#!/usr/bin/ruby
require "json"
require "libverbose"
class IoFile
  include JSON
  VarDir="#{ENV['HOME']}/.var"
  JsonDir=VarDir+"/json"
  attr_reader :time

  def initialize(type)
    @type=type
    @time=Time.now
    @v=Verbose.new('FILE')
    @logfile=@type+Time.now.year.to_s
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
  
  def save_frame(frame,id=nil)
    name=[@type,id].compact.join('_')
    open(VarDir+"/#{name}.bin",'w') {|f|
      @v.msg "Frame Saving for [#{name}]"
      f << frame
    }
    frame
  end

  def load_frame(id=nil)
    name=[@type,id].compact.join('_')
    @v.msg "Raw Status Loading for [#{name}]"
    frame=IO.read(VarDir+"/#{name}.bin")
    raise "No frame in File" unless frame
    @v.msg(frame.dump)
    frame
  end 
  
  def log_frame(frame,id=nil)
    @time=Time.now
    name=[@type,id].compact.join('_')
    line=["%.3f" % @time.to_f,id,frame.dump].compact.join(' ')
    save_frame(frame,id)
    open(VarDir+"/#{@logfile}.log",'a') {|f|
      @v.msg "Frame Logging for [#{name}]"
      f << line+"\n"
    }
    frame
  end

end
