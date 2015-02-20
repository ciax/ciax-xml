#!/usr/bin/ruby
require "libappexe"
require "libinsdb"
require "libfrmlist"

module CIAX
  module App
    class List < Site::List
      def initialize(inter_cfg={})
        attr={}
        attr[:frm_list]=Frm::List.new(inter_cfg)
        attr[:layer_db]=Ins::Db.new
        super(App,attr,inter_cfg)
        @cfg.layers[:app]=self
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
