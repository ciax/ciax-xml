#!/usr/bin/ruby
require "libwatexe"
require "libinsdb"
require "libapplist"

module CIAX
  module Wat
    class List < Site::List
      # inter_cfg must have :app_list
      def initialize(inter_cfg)
        super(Wat,{:layer_db => Ins::Db.new},inter_cfg)
        @cfg.layers[:wat]=self
      end
    end

    class Jump < LongJump; end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('chset')
      cfg=Config.new('test')
      cfg[:site_stat]=Prompt.new
      Frm::List.new(cfg)
      App::List.new(cfg)
      begin
        puts List.new(cfg).shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
