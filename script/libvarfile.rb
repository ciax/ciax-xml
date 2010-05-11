#!/usr/bin/ruby
require "libverbose"
class VarFile
  VarDir="#{ENV['HOME']}/.var"

  def initialize(type)
    @type=type
    @v=Verbose.new('FILE')
  end
  
  def save_stat(stat)
    open(VarDir+"/#{@type}.mar",'w') do |f|
      @v.msg "Status Saving for [#{@type}]"
      f << Marshal.dump(stat)
    end
  end
  
  def load_stat
    @v.msg("Status Loading for [#{@type}]")
    stat=Marshal.load(IO.read(VarDir+"/#{@type}.mar"))
    raise "No status in File" unless stat
    @v.msg(stat.inspect,1)
    stat
  end
  
  def save_frame(cmd,frame)
    open(VarDir+"/#{@type}_#{cmd}.bin",'w') do |f|
      @v.msg "Frame Saving for [#{@type}/#{cmd}]"
      f << frame
    end
  end

  def load_frame(cmd)
    @v.msg "Raw Status Loading for [#{@type}/#{cmd}]"
    frame=IO.read(VarDir+"/#{@type}_#{cmd}.bin")
    raise "No frame in File" unless frame
    @v.msg(frame.dump,1)
    frame
  end 

end
