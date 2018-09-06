#!/usr/bin/ruby
require 'liblist'
module CIAX
  module Site
    # @cfg[:db] associated site/layer should be set
    # This should be set [:db]
    class List < CIAX::List
      attr_reader :id, :db, :sub_list
      def initialize(super_cfg, atrb = Hashx.new)
        super
        super_cfg[:top_list] ||= self # Site Shared
        super_cfg[:layer_type] = 'site' # Site Shared
        @cfg[:column] = 2
        @id = @cfg[:proj]
        @run_list = []
      end

      def get(site)
        cobj = _list.key?(site) ? _list.get(site) : ___add(site)
        @sub_list.get(cobj.sub.id) if @sub_list
        @current = site
        cobj
      end

      def run
        @run_list.each { |s| get(s) }
        @sub_list.run if @sub_list
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

      def _store_db(db)
        @db = @cfg[:db] = type?(db, Db)
        # If @cfg[:site] is set, get() will be done at run();
        if @cfg.key?(:sites) # in case of sub_list(Frm::List)
          sites = @db.displist.valid_keys & @cfg[:sites]
          @run_list = sites.empty? ? @db.run_list : sites
          @current = sites.first
        end
        self
      end

      def ___add(site) # returns Exe
        # layer_module can be Frm,App,Wat,Hex
        atrb = { dbi: @db.get(site), sub_list: @sub_list }
        obj = layer_module::Exe.new(@cfg, atrb)
        _list.put(site, obj)
        obj
      end

      def _switch(site)
        # Change top_list as well as the lower layer changed
        @cfg[:top_list].get(site)
        super
      end

      class Jump < LongJump; end
    end
  end
end
