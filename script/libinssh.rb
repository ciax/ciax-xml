#!/usr/bin/ruby
require "liblocdb"
require "libfrmsh"
require "libappsh"
require "libhexsh"

module Ins
  class Layer < Sh::Layer
    def initialize(current,id=nil)
      super(current)
      fl=self['frm']=Frm::List.new(id)
      al=self['app']=App::List.new(fl)
      self['hex']=Hex::List.new(al)
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts Ins::Layer.new('app',ARGV.shift).shell
end
