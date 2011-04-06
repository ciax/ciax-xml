#!/usr/bin/ruby
require "json"
require "libverbose"
class IoFile
  VarDir="#{ENV['HOME']}/.var"
  JsonDir=VarDir+"/json"
  attr_reader :time

  def initialize(type)
    @type=type
    @time=Time.now
    @v=Verbose.new('FILE')
    @logfile=@type+'_'+Time.now.year.to_s
  end

  def save_stat(stat,tag=nil)
    base=[@type,tag].compact.join('_')
    fname=VarDir+"/#{base}.json"
    open(fname,'w') {|f|
      @v.msg{"Status Saving for [#{base}]"}
      f << JSON.dump(stat)
      if tag
        sbase=[@type,'latest'].compact.join('_')
        sname=VarDir+"/#{sbase}.json"
        File.unlink(sname) if File.exist?(sname)
        File.symlink(fname,sname)
        @v.msg{"Symboliclink to [#{sbase}]"}
      end
    }
    stat
  end

  def load_stat(tag=nil)
    base=[@type,tag].compact.join('_')
    @v.msg{"Status Loading for [#{base}]"}
    fname=VarDir+"/#{base}.json"
    raise SelectID,list_stat unless !tag || FileTest.exist?(fname)
    stat=JSON.load(IO.read(fname))
    raise "No status in File" unless stat
    @v.msg{stat.inspect}
    stat
  end

  def list_stat
    list=[]
    Dir.glob(VarDir+"/#{@type}_*.json"){|f|
      tag=f.slice(/#{@type}_(.+)\.json/,1)
      list << tag
    }
    "Tag=#{list}"
  end

  def save_json(stat)
    open(JsonDir+"/#{@type}.json",'w') {|f|
      @v.msg{"JSON Status Saving for [#{@type}]"}
      f << JSON.dump(stat)
    }
    stat
  end

  def load_json
    @v.msg{"JSON Status Loading for [#{@type}]"}
    stat=JSON.load(IO.read(JsonDir+"/#{@type}.json"))
    raise "No status in File" unless stat
    @v.msg{stat.inspect}
    stat
  end

  def save_frame(frame,tag=nil)
    base=[@type,tag].compact.join('_')
    open(VarDir+"/#{base}.bin",'w') {|f|
      @v.msg{"Frame Saving for [#{base}]"}
      f << frame
    }
    frame
  end

  def load_frame(tag=nil)
    base=[@type,tag].compact.join('_')
    @v.msg{"Raw Status Loading for [#{base}]"}
    frame=IO.read(VarDir+"/#{base}.bin")
    raise "No frame in File" unless frame
    @v.msg{frame.dump}
    frame
  end 

  def log_frame(frame,id=nil)
    @time=Time.now
    line=["%.3f" % @time.to_f,id,frame.dump].compact.join("\t")
    open(VarDir+"/#{@logfile}.log",'a') {|f|
      @v.msg{"Frame Logging for [#{id}]"}
      f << line+"\n"
    }
    frame
  end

end
