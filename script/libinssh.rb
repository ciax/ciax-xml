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
          update_layers(Frm::List.new.layers)
        elsif $opt['x']
          update_layers(Hex::List.new.layers)
        else
          update_layers(App::List.new.layers)
        end
      end
    end
  end

  if __FILE__ == $0
    GetOpts.new('faxet')
    puts Ins::Layer.new.shell(ARGV.shift)
  end
end
