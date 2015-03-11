#!/usr/bin/ruby
require "libsitelist"

module CIAX
  module Site
    class Layer < CIAX::List
      def initialize(inter_cfg={},attr={})
        super(Site,inter_cfg,attr)
        @cfg[:site_stat]=Prompt.new
        @cfg[:current_site]||=''
        @pars={:parameters => [{:default => @cfg[:current_site]}]}
        @cfg[:jump_groups] << @jumpgrp
      end

      def add_layer(layer)
        type?(layer,Module)
        str=layer.to_s.split(':').last
        layer::List.new(@cfg)
        @layer=str.downcase
        @cfg.layers.each{|k,v|
          id=k.to_s
          @jumpgrp.add_item(id,str+" mode",@pars)
          set(id,v)
        }
        self
      end

      def shell(id)
        layer=@layer
        begin
          dst=get(layer)
          if dst.list.key?(id)
            last=dst
          elsif last
            dst=last
          end
          dst.shell(id)
        rescue Site::Jump
          layer,id=$!.to_s.split(':')
          retry
        rescue InvalidID
          $opt.usage('(opt) [id]')
        end
      end
    end

    class Jump < LongJump; end
  end
end
