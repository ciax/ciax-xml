#!/usr/bin/ruby
require "libjumplist"
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
        str=layer.to_s.split(':').last
        id=str.downcase
        key="#{id}_list".to_sym
        lst=(@cfg[key]||=layer::List.new(@cfg))
        @jumpgrp.add_item(id,str+" mode",@pars)
        set(id,lst)
      end
    end

    class Jump < LongJump; end
  end
end
