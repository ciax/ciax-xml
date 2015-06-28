#!/usr/bin/ruby
require "liblist"
require "libsh"

module CIAX
  module Site
    # @cfg[:db] associated site/layer should be set
    # @cfg should have [:jump_group],[:db]
    # attr shoudl have [:jump_level]
    class List < List
      attr_reader :current_site
      def initialize(cfg,attr={})
        super
        @cfg[:layer]=@cfg[:jump_level]
        sites=@cfg[:db].displist
        verbose("List","Initialize")
        @jumpgrp.merge_items(sites)
        # For parameter of jump from another layer
        @current_site={:default => sites.keys.first,:list => sites.keys}
      end

      def exe(args) # As a individual cui command
        get(args.shift).exe(args,'local')
      end

      def get(site)
        unless @data.key?(site)
          add(site)
        end
        @current_site[:default]=site
        super
      end

      def shell(site)
        begin
          get(site).shell
        rescue @cfg[:jump_level]::Jump
          site=$!.to_s
          retry
        rescue InvalidID
          $opt.usage('(opt) [site]')
        end
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

      private
      def add(site)
        obj=@cfg[:layer].new(site,@cfg)
        put(site,obj.ext_shell)
      end
    end

    class Jump < LongJump; end
  end

  if __FILE__ == $0
    require "libfrmexe"
    require "libdevdb"
    ENV['VER']||='initialize'
    GetOpts.new('chset')
    site=ARGV.shift
    begin
      cfg=Config.new
      cfg[:jump_groups]=[]
      cfg[:jump_level]=Frm
      cfg[:db]=Dev::Db.new
      sl=Site::List.new(cfg)
      sl.shell(site)
    rescue InvalidID
      $opt.usage('(opt) [id]')
    end
  end
end
