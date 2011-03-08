#!/usr/bin/ruby
class Filter
  def initialize(cmd=nil)
    @cmd=cmd.to_s
  end

  def filter(str)
    return str if @cmd.empty?
    IO.popen(@cmd,'r+'){|f|
      f.write(str)
      f.close_write
      f.read
    }
  end
end
