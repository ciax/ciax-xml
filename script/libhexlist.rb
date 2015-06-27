#!/usr/bin/ruby
require "libhexexe"
require "libinsdb"
require "libwatlist"

module CIAX
  module Hex
    class List < Site::List
      def initialize(cfg={})
        super(Hex,cfg,{:db => Ins::Db.new})
        @cfg.layers[:hex]=self
      end
    end

    class Jump < LongJump; end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('chset')
      begin
        cfg=Config.new
        cfg[:jump_groups]=[]
        Frm::List.new(cfg)
        App::List.new(cfg)
        Wat::List.new(cfg)
        List.new(cfg).shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
