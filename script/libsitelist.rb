#!/usr/bin/ruby
require "liblayer"

module CIAX
  module Site
    # @cfg[:db] associated site/layer should be set
    # @cfg should have [:jump_groups]
    # This should be set [:db]
    class List < CIAX::List
      attr_reader :sub_list
      def initialize(cfg,attr={})
        super
        @sub_list=@cfg[:sub_list]
      end

      def set_db(db)
        @cfg[:db]=type?(db,Db)
        verbose("Initialize")
        if @cfg.key?(:site)
          @current=@cfg[:site]
        else
          @current=db.displist.keys.first
        end
        self
      end

      def exe(args) # As a individual cui command
        get(args.shift).exe(args,'local')
      end

      def get(site)
        unless @data.key?(site)
          add(site)
        end
        @current=site
        super
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

      def ext_shell
        extend(Shell).ext_shell
      end

      private
      def add(site)
        # layer_module can be Frm,App,Wat,Hex
        obj=layer_module.new(site,@cfg)
        put(site,obj.ext_shell)
      end

      module Shell
        include CIAX::List::Shell
        class Jump < LongJump; end

        def ext_shell
          super(Jump)
          @cfg[:jump_groups]+=[@jumpgrp]
          sites=@cfg[:db].displist
          @jumpgrp.merge_items(sites)
          self
        end
      end
    end
  end
end
