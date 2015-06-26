#!/usr/bin/ruby
require "libwatexe"
require "libinsdb"
require "libapplist"

module CIAX
  module Wat
    class List < Site::List
      def initialize(cfg)
        super(Wat,cfg,{:db => Ins::Db.new})
        @cfg.layers[:wat]=self
      end
    end

    class Jump < LongJump; end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('chset')
      begin
        cfg=Config.new
        cfg[:jump_groups]=[]
        cfg[:site_stat]=Prompt.new
        Frm::List.new(cfg)
        App::List.new(cfg)
        List.new(cfg).shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
