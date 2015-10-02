#!/usr/bin/ruby
require 'libsitelayer'
module CIAX
  module Site
    # @cfg[:db] associated site/layer should be set
    # This should be set [:db]
    class List < CIAX::List
      attr_reader :db, :sub_list
      def initialize(cfg, top_list, sub_mod = nil)
        cfg[:top_list] ||= top_list
        super(cfg)
        @sub_list = @cfg[:sub_list] = sub_mod.new(cfg) if sub_mod
      end

      def set_db(db)
        @db = @cfg[:db] = type?(db, Db)
        verbose { 'Initialize' }
        if @cfg.key?(:site)
          @current = @cfg[:site]
        else
          @current = db.displist.keys.first
        end
        self
      end

      def exe(args) # As a individual cui command
        get(args.shift).exe(args, 'local')
      rescue InvalidID
        OPT.usage('(opt) [id]')
      end

      def get(site)
        if @data.key?(site)
          cobj = super
          @sub_list.get(cobj.sub.id) if @sub_list
        else
          cobj = add(site)
        end
        @current = site
        cobj
      end

      def getstat(attr)
        get(attr['site']).stat.get(attr['var'])
      end

      def server(ary)
        ary.each do|site|
          sleep 0.3
          get(site).ext_server.server
        end.empty? && get(nil)
        sleep
      rescue InvalidID
        OPT.usage('(opt) [id] ....')
      end

      def ext_shell
        extend(Shell).ext_shell
      end

      private
      def add(site)
        # layer_module can be Frm,App,Wat,Hex
        obj = layer_module::Exe.new(site, @cfg)
        put(site, obj)
      end

      module Shell
        include CIAX::List::Shell
        class Jump < LongJump; end

        def ext_shell
          super(Jump)
          @cfg[:jump_site] = @jumpgrp
          sites = @cfg[:db].displist
          @jumpgrp.merge_items(sites)
          @sub_list.ext_shell if @sub_list
          self
        end

        def add(site)
          super.ext_shell
        end

        def switch(site)
          @cfg[:top_list].get(site)
          super
        end
      end
    end
  end
end
