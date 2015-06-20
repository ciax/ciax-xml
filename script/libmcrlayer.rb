#!/usr/bin/ruby
require "libmcrman"
require "libsitelayer"

module CIAX
  module Mcr
    class Layer < CIAX::List
      def initialize(inter_cfg={},attr={})
        super(Layer,inter_cfg,attr)
        sl=Site::Layer.new(@cfg).add_layer(Wat)
        sl.jumpgrp.add_item('mcr',"Mcr mode").cfg.proc{|ent|
          raise(Jump,ent.id)
        }
        mcr=Mcr::Man.new(@cfg)
        put('mcr',mcr)
        wg=mcr.cobj.loc.put(@cfg.layers[:app].jumpgrp).cfg.proc{|ent| sl.shell(ent.id,'app');exit }
      end

      def shell
        layer='mcr'
        begin
          get(layer).shell
        rescue Jump
          layer=$!.to_s
          retry
        rescue InvalidID
          $opt.usage('(opt) [id]')
        end
      end

      class Jump < LongJump; end
    end

    if __FILE__ == $0
      GetOpts.new('mnlrt')
      begin
        Layer.new.shell
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
