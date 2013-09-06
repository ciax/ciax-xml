#!/usr/bin/ruby
require "liblocdb"
require "libfrmsh"
require "libappsh"
require "libhexsh"

module CIAX
  module Ins
    class Layer < ShLayer
      def initialize
        super
        if $opt['f']
          fl=Frm::List.new
          add_layer('frm',fl)
        elsif $opt['x']
          hl=Hex::List.new
          add_layer('hex',hl)
          add_layer('app',hl.al)
          add_layer('frm',hl.al.fl)
        else
          al=App::List.new
          add_layer('app',al)
          add_layer('frm',al.fl)
        end
      end
    end
  end

  if __FILE__ == $0
    GetOpts.new('faxet')
    puts Ins::Layer.new.shell(ARGV.shift)
  end
end
