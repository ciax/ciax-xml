#!/usr/bin/ruby
require "libwatexe"
require "libinsdb"
require "libapplist"

module CIAX
  module Wat
    class List < Site::List
      def initialize(cfg)
        super(Wat,cfg,{:db => Ins::Db.new})
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
        List.new(cfg).shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
