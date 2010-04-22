#!/usr/bin/ruby
module StatIo
  VarDir="#{ENV['HOME']}/.var"
  
  def write_stat(type,stat)
    open(VarDir+"/#{type}.mar",w) do |f|
      f << Marshal.dump(stat)
    end
  end
  
  def read_stat(type)
    Marshal.load(IO.readlines(VarDir+"/#{type}.mar",nil).first)
  end
  
  def read_frame(type,cmd)
    IO.readlines(VarDir+"/#{type}_#{cmd}.bin",nil).first
  end 

end


