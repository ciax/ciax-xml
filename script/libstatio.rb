#!/usr/bin/ruby
module StatIo
  VarDir="#{ENV['HOME']}/.var"
  
  def write_stat(type,stat)
    open(VarDir+"/#{type}.mar",w) do |f|
      f << Marshal.dump(stat)
    end
  end
  
  def read_stat(type)
    Marshal.load(IO.read(VarDir+"/#{type}.mar"))
  end
  
  def read_frame(type,cmd)
    IO.read(VarDir+"/#{type}_#{cmd}.bin")
  end 

end


