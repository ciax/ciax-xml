#!/usr/bin/ruby
require "libfrmexe"
require "libdevdb"
require "libsitelist"

module CIAX
  module Frm
    class List < Site::List
      def initialize(cfg)
        super(Frm,cfg)
        @cfg[:db]=Dev::Db.new
        @cfg[:site_stat]=Prompt.new
        @cfg.layers[:frm]=self
        add_jump
      end
    end

    class Jump < LongJump; end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('chset')
      begin
        cfg=Config.new
        cfg[:jump_groups]=[]
        puts List.new(cfg).shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
