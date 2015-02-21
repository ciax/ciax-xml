#!/usr/bin/ruby
require "libhexexe"
require "libinsdb"
require "libwatlist"

module CIAX
  module Hex
    class List < Site::List
      def initialize(inter_cfg)
        super(Hex,{:layer_db => Ins::Db.new},inter_cfg)
        @cfg.layers[:hex]=self
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
      Wat::List.new(cfg)
      begin
        puts List.new(cfg).shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
