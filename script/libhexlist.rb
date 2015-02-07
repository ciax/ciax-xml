#!/usr/bin/ruby
# Ascii Pack
require "libhexexe"
require "libwatlist"

module CIAX
  module Hex
    class List < Site::List
      def initialize(upper=nil)
        super(Hex,upper)
        @cfg.layers[:hex]=self
        Wat::List.new(@cfg)
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
