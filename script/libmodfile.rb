#!/usr/bin/ruby
require "libverbose"

module ModFile
  include Verbose
  VarDir="#{ENV['HOME']}/.var"
  
  def save_stat(type,stat)
    open(VarDir+"/#{type}.mar",'w') do |f|
      msg "Status Saving for [#{type}]"
      f << Marshal.dump(stat)
    end
  end
  
  def load_stat(type)
    msg("Status Loading for [#{type}]")
    stat=Marshal.load(IO.read(VarDir+"/#{type}.mar"))
    msg(stat.inspect,1)
    stat
  end
  
  def save_frame(type,cmd,frame)
    open(VarDir+"/#{type}_#{cmd}.bin",'w') do |f|
      msg "Frame Saving for [#{type}/#{cmd}]"
      f << frame
    end
  end

  def load_frame(type,cmd)
    msg "Raw Status Loading for [#{type}/#{cmd}]"
    frame=IO.read(VarDir+"/#{type}_#{cmd}.bin")
    msg(frame.dump,1)
    frame
  end 

end





