#!/usr/bin/ruby
require "libhexexe"
require "libinsdb"
require "libwatlist"

module CIAX
  module Hex
    class List < Site::List
      def initialize(inter_cfg={})
        super(Hex,inter_cfg,{:layer_db => Ins::Db.new})
        @cfg[:site_stat]||=Prompt.new
        Wat::List.new(@cfg) unless @cfg.layers.key?(:wat)
        @cfg.layers[:hex]=self
      end
    end

    class Jump < LongJump; end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('chset')
      begin
        puts List.new.shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
