#!/usr/bin/ruby
require "libappexe"
require "libinsdb"
require "libfrmlist"

module CIAX
  module App
    class List < Site::List
      # inter_cfg must have :frm_list
      def initialize(inter_cfg=nil)
        super(App,{:layer_db => Ins::Db.new},inter_cfg)
        Frm::List.new(@cfg) unless @cfg.layers.key?(:frm)
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
