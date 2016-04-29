#!/usr/bin/ruby
require 'liblist'
module CIAX
  module Site
    # @cfg[:db] associated site/layer should be set
    # This should be set [:db]
    class List < CIAX::List
      attr_reader :db, :sub_list
      def initialize(cfg, atrb = Hashx.new)
        super
        cfg[:top_list] ||= self # Site Shared
        cfg[:layer_type] = 'site' # Site Shared
        @cfg[:column] = 2
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
        @db.run_list.each { |s| get(s) } if @list.empty?
        @list.each_value { |obj| obj.run }
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

      def _get_sites
        return unless @cfg.key?(:sites)
        sites = @cfg[:sites]
        get(nil) if (sites & @db.displist.valid_keys).empty?
        @current = sites.each { |s| get(s) }.first
      end

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
