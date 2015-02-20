#!/usr/bin/ruby
require "libwatexe"
require "libinsdb"
require "libsitelist"

module CIAX
  module Wat
    class List < Site::List
      def initialize(layer_cfg={})
        layer_cfg[:layer_db]=Ins::Db.new
        super(Wat,layer_cfg)
        @cfg.layers[:wat]=self
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
