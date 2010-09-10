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
    @logfile=@type+'_'+Time.now.year.to_s
  end

  def save_stat(stat,suffix='')
    raise("Not valid charactors") unless suffix == '' || /^[\w]+$/ === suffix
    fname=VarDir+"/#{@type}#{suffix}.mar"
    open(fname,'w') {|f|
      @v.msg{"Status Saving for [#{@type}#{suffix}]"}
      f << Marshal.dump(stat)
    }
    stat
  end

  def load_stat(suffix='')
    @v.msg{"Status Loading for [#{@type}#{suffix}]"}
    fname=VarDir+"/#{@type}#{suffix}.mar"
    raise(list_stat) unless suffix == '' || FileTest.exist?(fname)
    stat=Marshal.load(IO.read(fname))
    raise "No status in File" unless stat
    @v.msg{stat.inspect}
    stat
  end

  def list_stat
    list=["== Tag list =="]
    Dir.glob(VarDir+"/#{@type}_*.mar"){|f|
      /#{@type}_(.+)\.mar/ =~ f
      list << " #{$1.tr('_',' ')}"
    }
    list.join("\n")
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

  def save_frame(frame,id=nil)
    name=id ? @type+'_'+id.tr(':','_') : @type
    open(VarDir+"/#{name}.bin",'w') {|f|
      @v.msg{"Frame Saving for [#{name}]"}
      f << frame
    }
    frame
  end

  def load_frame(id=nil)
    name=id ? @type+'_'+id.tr(':','_') : @type
    @v.msg{"Raw Status Loading for [#{name}]"}
    frame=IO.read(VarDir+"/#{name}.bin")
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
