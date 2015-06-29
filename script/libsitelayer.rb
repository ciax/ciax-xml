#!/usr/bin/ruby
require "liblist"

module CIAX
  module Site
    class Layer < CIAX::List
      attr_reader :default
      # list object can be (Frm,App,Wat,Hex)
      def add_layer(lobj)
        type?(lobj,List)
        @default=m2id(lobj.cfg[:layer])
        put(@default,lobj)
        pars={:parameters => [lobj.current_site]}
        @jumpgrp.add_item(@default,@default.capitalize+" mode",pars)
        self
      end

      def shell(site,layer=nil)
        begin
          get(layer||@default).shell(site)
        rescue @cfg[:jump_level]::Jump
          layer,site=$!.to_s.split(':')
          retry
        rescue InvalidID
          $opt.usage('(opt) [id]')
        end
      end

      class Jump < LongJump; end
    end
  end

  if __FILE__ == $0
    require "libhexexe"
    GetOpts.new("els")
    site=ARGV.shift
    cfg=Config.new
    cfg[:jump_groups]=[]
    sl=cfg[:layer_list]=Site::Layer.new(cfg)
    begin
      sl.add_layer(Hex::List.new(cfg))
      sl.shell(site)
    rescue InvalidID
      $opt.usage('(opt) [id]')
    end
  end
end
