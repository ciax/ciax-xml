#!/usr/bin/ruby
require "libsitelayer"

module CIAX
  module Site
    # @cfg[:db] associated site/layer should be set
    # @cfg should have [:jump_group],[:layer_list]
    # This should be set [:layer],[:db]
    class List < CIAX::List
      attr_reader :current_site
      def initialize(cfg,attr={})
        attr[:jump_class]=cfg[:layer]::Jump
        super
      end

      def set_db(db)
        @cfg[:db]=type?(db,Db)
        sites=db.displist
        verbose("List","Initialize")
        @jumpgrp.merge_items(sites)
        # For parameter of jump from another layer
        @current_site={:default => sites.keys.first,:list => sites.keys}
        self
      end

      def sub_list(layer)
        if @cfg.all_key?(:layer_list)
          @cfg[:layer_list].add_layer(layer)
        else
          layer::List.new(@cfg)
        end
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
        rescue Jump
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

      class Jump < LongJump; end
    end
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
      cfg[:layer]=Frm
      sl=Site::List.new(cfg)
      sl.set_db(Dev::Db.new)
      sl.shell(site)
    rescue InvalidID
      $opt.usage('(opt) [id]')
    end
  end
end
