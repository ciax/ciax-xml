#!/usr/bin/ruby
require "libhexexe"
require "libinsdb"
require "libsitelist"

module CIAX
  module Hex
    class List < Site::List
      def initialize(layer_cfg={})
        layer_cfg[:layer_db]=Ins::Db.new
        super(Hex,layer_cfg)
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
