#!/usr/bin/ruby
require "liblocdb"
require "libfrmsh"
require "libappsh"
require "libhexsh"

module Ins
  class Layer < Sh::Layer
    def initialize(id)
      fl=self['frm']=Frm::List.new(id)
      self['app']=App::List.new(fl)
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts Ins::Layer.new(ARGV.shift).shell
end
