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
      def initialize(upper=nil)
        super(Site,upper)
        @cfg[:ldb]||=Db.new
        @jumpgrp.update_items(@cfg[:ldb].list)
        @cfg[:site]||=''
      end

      def get(site)
        set(site,add(site)) unless @data.key?(site)
        @cfg[:site].replace(site)
        super
      end

      def server(ary)
        ary.each{|i|
          sleep 0.3
          get(i)
        }.empty? && get(nil)
        sleep
      rescue InvalidID
        $opt.usage('(opt) [id] ....')
      end
    end

    class Jump < LongJump; end
  end
end
