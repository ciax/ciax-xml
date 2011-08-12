#!/usr/bin/ruby
class Interact
  def initialize(what)
    case what
    when Array
      require 'libshell'
      Shell.new(what){|line| yield line}
    when String
      require 'libserver'
      Server.new(what.to_i){|line| yield line}
    end
  end
end
