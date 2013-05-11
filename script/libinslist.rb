#!/usr/bin/ruby
require "liblocdb"
require "libfrmsh"
require "libappsh"
require "libhexsh"

module Ins
  class List < Sh::Layer
    def initialize(id)
      super
      fl=self['frm']=Frm::List.new(id)
      self['app']=App::List.new(fl)
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts Ins::List.new(ARGV.shift).shell
end
