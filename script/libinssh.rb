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
          update(Frm::List.new.layers)
        elsif $opt['x']
          update(Hex::List.new.layers)
        else
          update(App::List.new.layers)
        end
        update_layers
      end
    end
  end

  if __FILE__ == $0
    GetOpts.new('faxet')
    puts Ins::Layer.new.shell(ARGV.shift)
  end
end
