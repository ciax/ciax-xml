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
        fl=self['frm']=Frm::List.new(id,@swlgrp)
        al=self['app']=App::List.new(fl,@swlgrp)
        self['hex']=Hex::List.new(al,@swlgrp)
      end
    end
  end

  if __FILE__ == $0
    GetOpts.new('faxet')
    puts Ins::Layer.new(ARGV.shift).shell
  end
end
