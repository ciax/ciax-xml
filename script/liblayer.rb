#!/usr/bin/ruby
require "liblist"
require "libcommand"
require "libsitedb"

module CIAX
  module Layer
    include JumpList
    # Layer List
    class List < List
      def initialize(upper=nil)
        super(Layer,upper)
        @cfg[:site]||=''
        @cfg[:ldb]||=Site::Db.new
        @ver_color=4
        @pars={:parameters => [{:default => @cfg[:site]}]}
      end

      def add_layer(layer)
        type?(layer,Module)
        str=layer.to_s.split(':').last
        id=str.downcase
        key="#{id}_list".to_sym
        lst=(@cfg[key]||=layer::List.new(@cfg))
        @jumpgrp.add_item(id,str+" mode",@pars)
        self[id]=lst
      end
    end

    class Jump < LongJump; end
  end
end
