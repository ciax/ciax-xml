#!/usr/bin/ruby
require "libsitelist"

module CIAX
  module Site
    class Layer < CIAX::List
      attr_reader :default
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
        @default=m2id(layer_mod)
        sid=m2id(site_mod)
        site_db=(@site_db[sid]||=site_mod::Db.new)
        lst=List.new(@cfg,{:jump_level => layer_mod,:db => site_db})
        put(@default,lst)
        pars={:parameters => [lst.current_site]}
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
    require "libwatexe"
    GetOpts.new("els")
    site=ARGV.shift
    cfg=Config.new
    cfg[:jump_groups]=[]
    sl=cfg[:layers]=Site::Layer.new(cfg)
    sl.add_layer(Frm,Dev)
    sl.add_layer(App,Ins)
    sl.add_layer(Wat,Ins)
    sl.shell(site)
  end
end
