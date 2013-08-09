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
        fl=add('frm',Frm::List.new)
        return if $opt['f']
        al=add('app',App::List.new(fl))
        add('hex',Hex::List.new(al)) if $opt['x']
      end
    end
  end

  if __FILE__ == $0
    GetOpts.new('faxet')
    puts Ins::Layer.new.shell(ARGV.shift)
  end
end
