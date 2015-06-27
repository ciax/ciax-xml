#!/usr/bin/ruby
require "libsitelist"

module CIAX
  module Site
    class Layer < CIAX::List
      def initialize(cfg,attr={})
        super(Layer,cfg,attr)
      end

      def add_layer(layer)
        type?(layer,Module)
        id=m2id(layer)
        lst=layer::List.new(@cfg)
        put(id,lst)
        pars={:parameters => [lst.current_site]}
        @jumpgrp.add_item(id,id.capitalize+" mode",pars)
        @init_layer=id
        self
      end

      class Jump < LongJump; end
    end
  end
  
  if __FILE__ == $0
    require "libapplist"
    GetOpts.new("els")
    id=ARGV.shift
    cfg=Config.new
    cfg[:jump_groups]=[]
    sl=Site::Layer.new(cfg)
    sl.add_layer(Frm)
    sl.add_layer(App)
    sl.shell('app',id)
  end
end
