#!/usr/bin/ruby
require 'liblist'
module CIAX
  module Site
    # @cfg[:db] associated site/layer should be set
    # This should be set [:db]
    class List < CIAX::List
      attr_reader :db, :sub_list
      def initialize(cfg, atrb = Hashx.new)
        cfg[:top_list] ||= self
        cfg[:layer_type] = 'site'
        atrb[:column] = 2
        super
      end

      def store_db(db)
        @db = @cfg[:db] = type?(db, Db)
        if @cfg.key?(:site)
          @current = @cfg[:site]
        else
          @current = db.displist.valid_keys.first
        end
        self
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

      # Server Setting
      def run(sites = [])
        sites = @db.run_list if sites.empty?
        get(nil) if sites.empty? # Show usage
        sites.each { |s| get(s).exe(['upd']) }
        self
      end

      def ext_shell
        extend(CIAX::List::Shell).ext_shell(Jump)
        @cfg[:jump_site] = @jumpgrp
        sites = @cfg[:db].displist
        @jumpgrp.ext_grp.merge_items(sites)
        self
      end

      private

      def add(site)
        # layer_module can be Frm,App,Wat,Hex
        obj = layer_module::Exe.new(site, @cfg, db: @db, sub_list: @sub_list)
        @list.put(site, obj)
      end

      def switch(site)
        # Change top_list as well as the lower layer changed
        @cfg[:top_list].get(site)
        super
      end

      class Jump < LongJump; end
    end
  end
end
