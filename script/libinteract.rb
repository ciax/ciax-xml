#!/usr/bin/ruby
class Interact
  def initialize(prom,port=nil)
    if port
      require 'libserver'
      Server.new(prom,port.to_i){|line| yield line}
    else
      require 'libshell'
      Shell.new(prom){|line| yield line}
    end
  end
end
