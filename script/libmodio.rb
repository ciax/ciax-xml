#!/usr/bin/ruby
require "libverbose"

module ModIo
  include Verbose
  VarDir="#{ENV['HOME']}/.var"
  
  def write_stat(type,stat)
    open(VarDir+"/#{type}.mar",'w') do |f|
      msg "Status Writing for [#{type}]"
      f << Marshal.dump(stat)
    end
  end
  
  def read_stat(type)
    msg("Status Reading for [#{type}]")
    Marshal.load(IO.read(VarDir+"/#{type}.mar"))
  end
  
  def write_frame(type,cmd,frame)
    open(VarDir+"/#{type}_#{cmd}.bin",'w') do |f|
      msg "Frame Writing for [#{type}/#{cmd}]"
      f << frame
    end
  end

  def read_frame(type,cmd)
    msg "Raw Status Reading for [#{type}/#{cmd}]"
    IO.read(VarDir+"/#{type}_#{cmd}.bin")
  end 

end
