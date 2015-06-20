#!/usr/bin/ruby
require "libsitelist"

module CIAX
  module Site
    class Layer < CIAX::List
      def initialize(cfg,attr={})
        super(Layer,cfg,attr)
        @cfg[:site_stat]=Prompt.new
        @cfg[:current_site]||=''
        @pars={:parameters => [{:default => @cfg[:current_site]}]}
        @cfg[:jump_groups] << @jumpgrp
      end

      def add_layer(layer)
        type?(layer,Module)
        layer::List.new(@cfg)
        @init_layer=layer.to_s.split(':').last.downcase
        @cfg.layers.each{|k,v|
          id=k.to_s
          @jumpgrp.add_item(id,id.capitalize+" mode",@pars)
          put(id,v)
        }
        self
      end

      def shell(id,layer=@init_layer)
        begin
          dst=get(layer)
          if dst.key?(id)
            last=dst
          elsif last
            dst=last
          end
          dst.shell(id)
        rescue Jump
          layer,id=$!.to_s.split(':')
          retry
        rescue InvalidID
          $opt.usage('(opt) [id]')
        end
      end

      class Jump < LongJump; end
    end
  end
end
