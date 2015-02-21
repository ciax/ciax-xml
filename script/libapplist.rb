#!/usr/bin/ruby
require "libappexe"
require "libinsdb"
require "libfrmlist"

module CIAX
  module App
    class List < Site::List
      # inter_cfg must have :frm_list
      def initialize(inter_cfg)
        super(App,{:layer_db => Ins::Db.new},inter_cfg)
        @cfg.layers[:app_list]=self
      end
    end

    class Jump < LongJump; end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('chset')
      cfg=Config.new('test')
       begin
         Frm::List.new(cfg)
         puts List.new(cfg).shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
