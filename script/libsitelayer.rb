#!/usr/bin/ruby
require "libsitelist"

module CIAX
  module Site
    class Layer < CIAX::List
      def initialize(cfg,attr={})
        super
        @site_db={}
      end

      # layer_mod can be (Frm,App,Wat,Hex)
      # site_mod can be (Dev,Ins)
      def add_layer(layer_mod,site_mod=nil)
        type?(layer_mod,Module)
        if site_mod
          type?(site_mod,Module)
        else
          site_mod=layer_mod
        end
        lid=m2id(layer_mod)
        sid=m2id(site_mod)
        site_db=site_mod::Db.new
        lst=List.new(@cfg,{:jump_level => layer_mod,:db => site_db})
        put(lid,lst)
        pars={:parameters => [lst.current_site]}
        @jumpgrp.add_item(lid,lid.capitalize+" mode",pars)
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
    sl.add_layer(Frm,Dev)
    sl.get('frm').shell(id)
  end
end
