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
      end

      def add_layer(layer)
        type?(layer,Module)
        id=layer.to_s.split(':').last.downcase
        @jumpgrp.add_item(id,id.capitalize+" mode",@pars)
        put(id,layer::List.new(@cfg))
        @init_layer=id
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
