#!/usr/bin/ruby
require "libmcrman"
require "libsitelayer"

module CIAX
  module Mcr
    class Layer < CIAX::List
      def initialize(inter_cfg={},attr={})
        super(Layer,inter_cfg,attr)
        sl=Site::Layer.new(@cfg).add_layer(Wat)
        sl.jumpgrp.add_item('mcr',"Mcr mode").set_proc{|ent|
          raise(Jump,ent.id)
        }
        mcr=Mcr::Man.new(@cfg)
        set('mcr',mcr)
        wg=mcr.cobj.lodom.add_group('caption'=>"App Mode",'color' => 9)
        wg.update_items(@cfg.layers[:app].list).set_proc{|ent| sl.shell(ent.id);'' }
      end

      def shell(site='crt')
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
