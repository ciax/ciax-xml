#!/usr/bin/ruby
require "libwatexe"
require "libinsdb"
require "libapplist"

module CIAX
  module Wat
    class List < Site::List
      def initialize(cfg)
        super(Wat,cfg)
        @cfg[:db]=Ins::Db.new
        @cfg.layers[:wat]=self
        add_jump
      end
    end

    class Jump < LongJump; end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('chset')
      begin
        cfg=Config.new
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
