#!/usr/bin/ruby
require "liblist"

module CIAX
  module Site
    class Layer < CIAX::List
      def initialize(cfg,attr={})
        attr[:layer_list]=self
        attr[:jump_class]=Jump
        super
      end

      # list object can be (Frm,App,Wat,Hex)
      def add_layer(layer)
        type?(layer,Module)
        sl=layer::List.new(@cfg)
        put(m2id(layer),sl)
        sl
      end

      def ext_shell
        super
        keys.each{|id|
          sl=get(id).ext_shell
          pars={:parameters => [sl.current_site]}
          @jumpgrp.add_item(id,id.capitalize+" mode",pars)
        }
        self
      end

      def shell(site,layer=nil)
        begin
          get(layer||keys.last).shell(site)
        rescue Jump
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
    sl=Site::Layer.new(cfg)
    begin
      sl.add_layer(Hex)
      sl.ext_shell.shell(site)
    rescue InvalidID
      $opt.usage('(opt) [id]')
    end
  end
end
