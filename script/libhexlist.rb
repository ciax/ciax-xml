#!/usr/bin/ruby
require "libhexexe"
require "libinsdb"
require "libwatlist"

module CIAX
  module Hex
    class List < Site::List
      def initialize(cfg={})
        super(Hex,cfg,{:db => Ins::Db.new})
      end
    end

    class Jump < LongJump; end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('chset')
      cfg=Config.new
      cfg[:jump_groups]=[]
      sl=cfg[:layers]=Site::Layer.new(cfg)
      begin
        sl.add_layer(Frm)
        sl.add_layer(App)
        sl.add_layer(Wat)
        List.new(cfg).shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
