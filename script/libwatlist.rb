#!/usr/bin/ruby
require "libwatexe"
require "libapplist"

module CIAX
  module Wat
    class List < Site::List
      def initialize(upper=nil)
        super(Wat,upper)
        @cfg.layers[:wat]=self
        App::List.new(@cfg)
      end

      def add(id)
        @cfg[:db]=@cfg[:ldb].set(id)[:adb]
        set(id,Wat.new(@cfg))
      end
    end

    class Jump < LongJump; end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('chlset')
      begin
        puts List.new.shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
