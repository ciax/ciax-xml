#!/usr/bin/ruby
require 'liblist'
module CIAX
  module Site
    # @cfg[:db] associated site/layer should be set
    # This should be set [:db]
    class List < CIAX::List
      attr_reader :id, :db, :sub_list
      def initialize(cfg, atrb = Hashx.new)
        super
        cfg[:top_list] ||= self # Site Shared
        cfg[:layer_type] = 'site' # Site Shared
        @cfg[:column] = 2
        @id = @cfg[:proj]
        @run_list = []
      end

      def store_db(db)
        @db = @cfg[:db] = type?(db, Db)
        _get_sites
        self
      end

      def get(site)
        cobj = @list.key?(site) ? @list.get(site) : add(site)
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

      # If :site is set, get() will be done at run();
      def _get_sites
        return unless @cfg.key?(:sites) # in case of sub_list(Frm::List)
        sites = @db.displist.valid_keys & @cfg[:sites]
        @run_list = sites.empty? ? @db.run_list : sites
        @current = sites.first
      end

      def add(site)
        # layer_module can be Frm,App,Wat,Hex
        atrb = { dbi: @db.get(site), sub_list: @sub_list }
        obj = layer_module::Exe.new(@cfg, atrb)
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
