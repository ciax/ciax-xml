#!/usr/bin/ruby
require "libfrmexe"
require "libsitelist"

module CIAX
  module Frm
    class List < Site::List
      def initialize(upper=nil)
        super(Frm,upper)
        @cfg.layers[:frm]=self
      end

      def add(id)
        cfg=Config.new("frm_list",@cfg).update(@cfg[:ldb].set(id))
        set(id,Frm.new(cfg))
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
