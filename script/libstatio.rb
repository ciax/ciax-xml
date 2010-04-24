#!/usr/bin/ruby
require "libverbose"

module StatIo
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
  
  def read_frame(type,cmd)
    msg "Raw Status Reading for [#{type}/#{cmd}]"
    IO.read(VarDir+"/#{type}_#{cmd}.bin")
  end 

end


