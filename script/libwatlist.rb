#!/usr/bin/ruby
require "libwatexe"
require "libinsdb"
require "libapplist"

module CIAX
  module Wat
    class List < Site::List
      def initialize(inter_cfg={})
        super(Wat,inter_cfg,{:layer_db => Ins::Db.new})
        @cfg[:site_stat]||=Prompt.new
        App::List.new(@cfg) unless @cfg.layers.key?(:app)
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
