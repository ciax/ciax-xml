#!/usr/bin/ruby
require "liblist"
require "libcommand"
require "libsitedb"

module CIAX
  module Layer
    # Layer List
    class List < List
      def initialize(upper=nil)
        super(Layer,upper)
        @cfg[:site]||=''
        @cfg[:ldb]||=Site::Db.new
        @pars={:parameters => [{:default => @cfg[:site]}]}
      end

      def add_layer(layer)
        type?(layer,Module)
        str=layer.to_s.split(':')[1]
        id=str.downcase.to_sym
        layer.new(@cfg)
        @cfg.layers.each{|k,v|
          id=k.to_s
          @jumpgrp.add_item(id,str+" mode",@pars)
          set(id,v)
        }
      end
    end

    class Jump < LongJump; end
  end
end
