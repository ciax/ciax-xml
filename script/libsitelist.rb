#!/usr/bin/ruby
require 'liblist'
module CIAX
  module Site
    # @cfg[:db] associated site/layer should be set
    # This should be set [:db]
    class List < CIAX::List
      attr_reader :db, :sub_list
      def initialize(cfg, atrb = {})
        cfg[:top_list] ||= self
        cfg[:layer_type] = 'site'
        atrb[:column] = 2
        super
      end

      def init_sub(sub_mod)
        @sub_list = sub_mod.new(@cfg)
      end

      def store_db(db)
        @db = @cfg[:db] = type?(db, Db)
        if @cfg.key?(:site)
          @current = @cfg[:site]
        else
          @current = db.displist.keys.first
        end
        self
      end

      def exe(args) # As a individual cui command
        get(args.shift).exe(args, 'local')
      end

      def get(site)
        if @list.key?(site)
          cobj = @list.get(site)
          @sub_list.get(cobj.sub.id) if @sub_list
        else
          cobj = add(site)
        end
        @current = site
        cobj
      end

      def ext_shell
        extend(Shell).ext_shell
      end

      # Server Setting
      def run(sites = [])
        sites << nil if sites.empty?
        sites.each { |s| get(s) }
        self
      end

      private

      def add(site)
        # layer_module can be Frm,App,Wat,Hex
        obj = layer_module::Exe.new(site, @cfg, db: @db, sub_list: @sub_list)
        @list.put(site, obj)
      end

      def switch(site)
        @cfg[:top_list].get(site)
        super
      end

      # Shell extension for Site::List
      module Shell
        include CIAX::List::Shell
        class Jump < LongJump; end

        def ext_shell
          super(Jump)
          @cfg[:jump_site] = @jumpgrp
          sites = @cfg[:db].displist
          @jumpgrp.ext_grp.merge_items(sites)
          @sub_list.ext_shell if @sub_list
          self
        end

        def add(site)
          obj = super.ext_shell
          obj.cobj.loc.add_jump
          obj
        end
      end
    end
  end
end
