#!/usr/bin/ruby
require "libfrmexe"
require "libdevdb"
require "libsitelist"

module CIAX
  module Frm
    class List < Site::List
      def initialize(layer_cfg={})
        layer_cfg[:layer_db]=Dev::Db.new
        super(Frm,layer_cfg)
        @cfg.layers[:frm]=self
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
