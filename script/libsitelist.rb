#!/usr/bin/ruby
require "libjumplist"
require "libcommand"
require "libsitedb"

module CIAX
  module Site
    include JumpList
    # Site List
    class List < List
      # shdom: Domain for Shared Command Groups
      def initialize(layer,upper=nil)
        super(Site,upper)
        @cfg[:ldb]||=Db.new
        @jumpgrp.update_items(@cfg[:ldb].list)
        @cfg[:site]||=''
      end

      def [](site)
        if key?(site)
          @cfg[:site].replace(site)
          super
        else
          exe=self[site]=add(site)
          @cfg[:site].replace(site)
          exe
        end
      end

      def server(ary)
        ary.each{|i|
          sleep 0.3
          self[i]
        }.empty? && self[nil]
        sleep
      rescue InvalidID
        $opt.usage('(opt) [id] ....')
      end
    end

    class Jump < LongJump; end
  end
end
