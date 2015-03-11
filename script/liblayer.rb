#!/usr/bin/ruby
require "libmcrman"

module CIAX
  module Mcr
    class Layer < CIAX::List
      def initialize(inter_cfg={},attr={})
        super(Layer,inter_cfg,attr)
        @cfg[:jump_groups] << @jumpgrp
        @jumpgrp.add_item('mcr',"Mcr mode")
        mcr=Mcr::Man.new(@cfg)
        set('mcr',mcr)
        app=mcr.cfg.layers[:app]
        wg=mcr.cobj.lodom.add_group('caption'=>"App Mode",'color' => 9)
        wg.update_items(app.list).set_proc{|ent| app.shell(ent.id);'' }
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
