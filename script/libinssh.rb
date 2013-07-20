#!/usr/bin/ruby
require "liblocdb"
require "libfrmsh"
require "libappsh"
require "libhexsh"

module CIAX
  module Ins
    class Layer < Sh::Layer
      def initialize(id=nil)
        if $opt['f']
          current='frm'
        elsif $opt['x']
          current='hex'
        else
          current='app'
        end
        super(current)
        al=add('frm',id,Frm::List)
        hl=add('app',al,App::List)
        add('hex',hl,Hex::List)
      end
    end
  end

  if __FILE__ == $0
    GetOpts.new('faxet')
    puts Ins::Layer.new(ARGV.shift).shell
  end
end
