#!/usr/bin/ruby
require "libfrmexe"
require "libdevdb"
require "libsitelist"

module CIAX
  module Frm
    class List < Site::List
      def initialize(inter_cfg={})
        super(Frm,{:layer_db =>Dev::Db.new},inter_cfg)
        @cfg.layers[:frm_list]=self
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
