#!/usr/bin/ruby
require "json"
require "libverbose"
class VarFile
  include JSON
  VarDir="#{ENV['HOME']}/.var"

  def initialize(type)
    @type=type
    @v=Verbose.new('FILE')
  end
  
  def save_stat(stat)
    open(VarDir+"/#{@type}.json",'w') do |f|
      @v.msg "Status Saving for [#{@type}]"
      f << JSON.dump(stat)
    end
    stat
  end
  
  def load_stat
    @v.msg("Status Loading for [#{@type}]")
    stat=JSON.load(IO.read(VarDir+"/#{@type}.json"))
    raise "No status in File" unless stat
    @v.msg(stat.inspect,1)
    stat
  end
  
  def save_frame(cmd,frame)
    open(VarDir+"/#{@type}_#{cmd}.bin",'w') do |f|
      @v.msg "Frame Saving for [#{@type}/#{cmd}]"
      f << frame
    end
    frame
  end

  def load_frame(cmd)
    @v.msg "Raw Status Loading for [#{@type}/#{cmd}]"
    frame=IO.read(VarDir+"/#{@type}_#{cmd}.bin")
    raise "No frame in File" unless frame
    @v.msg(frame.dump,1)
    frame
  end 

end
