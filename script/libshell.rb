#!/usr/bin/ruby
require "readline"

class Shell
  def initialize(ocmd=nil,icmd=nil)
    @ocmd=ocmd.to_s
    @icmd=icmd.to_s
  end

  def filter(str)
    return str if @ocmd.empty?
    IO.popen(@ocmd,'r+'){|f|
      f.write(str)
      f.close_write
      f.read
    }
  end

  def input(prompt)
    Readline.readline(prompt,true) || yield
  end
end
