#!/usr/bin/ruby
require "libsitelayer"

module CIAX
  module Site
    # @cfg[:db] associated site/layer should be set
    # @cfg should have [:jump_group],[:layer_list]
    # This should be set [:db]
    class List < CIAX::List
      attr_reader :parameter
      def initialize(cfg,attr={})
        super
        @current_site=''
      end

      def set_db(db)
        @cfg[:db]=type?(db,Db)
        verbose("Initialize")
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
        @current_site.replace(site)
        super
      end

      def ext_shell
        super(Jump)
        sites=@cfg[:db].displist
        @jumpgrp.merge_items(sites)
        # For parameter of jump from another layer
        @parameter={:default => @current_site,:list => sites.keys}
        @cfg[:sub_list].ext_shell if @cfg.key?(:sub_list) # Limit self level
        self
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
        ary.each{|site|
          sleep 0.3
          get(site).ext_server.server
        }.empty? && get(nil)
        sleep
      rescue InvalidID
        $opt.usage('(opt) [id] ....')
      end

      private
      def add(site)
        obj=layer_module.new(site,@cfg)
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
      sl=Frm::List.new(cfg)
      sl.set_db(Dev::Db.new)
      sl.shell(site)
    rescue InvalidID
      $opt.usage('(opt) [id]')
    end
  end
end
