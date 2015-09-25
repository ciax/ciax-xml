#!/usr/bin/ruby
require "libexe"
#Specific for Site Layers
module CIAX
  module Site
    class Exe < Exe # Having server status {id,msg,...}
    attr_reader :sub
    def initialize(id,cfg=Config.new,attr={})
      super
      @cls_color=13
      # layer is Frm,App,Wat,Hex
    end
  end
end
