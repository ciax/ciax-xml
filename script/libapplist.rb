#!/usr/bin/ruby
require "libappexe"
require "libinsdb"
require "libfrmlist"

module CIAX
  module App
    class List < Site::List
      def initialize(cfg)
        super(App,cfg,{:db => Ins::Db.new})
        @cfg.layers[:app]=self
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
        List.new(cfg).shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
