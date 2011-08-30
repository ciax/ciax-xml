#!/usr/bin/ruby
require 'libverbose'
require 'libstat'
require 'libmodio'

class IoField < Field
  include ModIo
  def initialize(id,type)
    @v=Verbose.new("stat",5)
    raise SelectID," No ID" unless id
    @type=type+"_#{id}"
    load
  end
end
