#!/usr/bin/ruby
require 'liblist'
module CIAX
  module Site
    # @cfg[:db] associated site/layer should be set
    # This should be set [:db]
    class List < CIAX::List
      attr_reader :db, :sub_list
      def initialize(super_cfg, atrb = Hashx.new)
        super
        super_cfg[:layer_type] = 'site' # Site Shared
        @cfg[:column] = 2
        @run_list = []
      end

      def get(site)
        eobj = _list.key?(site) ? super : ___add(site)
        @sub_list.get(eobj.sub.id) if @sub_list
        @current = site
        eobj
      end

      def run
        @run_list.each { |s| get(s) }
        self
      end

      def switch(site)
        # Change top_list as well as the lower layer changed
        @cfg[:super_list].switch(site) if @cfg.key?(:super_list)
        super
      end

      def ext_shell
        extend(Shell).ext_shell
      end

      def sub_atrb
        { opt: @cfg[:opt].sub_opt, super_list: self }
      end

      def exe_atrb(site)
        { dbi: @db.get(site), sub_list: @sub_list }
      end

      private

      def _store_db(db)
        @db = @cfg[:db] = type?(db, Db)
        # If @cfg[:site] is set, get() will be done at run();
        if @cfg.key?(:sites) # in case of sub_list(Frm::List)
          sites = @db.displist.valid_keys & @cfg[:sites]
          @run_list = sites.empty? ? @db.run_list : sites
        end
        self
      end

      def ___add(site) # returns Exe
        # layer_module can be Frm,App,Wat,Hex
        eobj = layer_module::Exe.new(@cfg, exe_atrb(site))
        _list.put(site, eobj)
        eobj
      end

      # Shell module which is Site::List specific
      module Shell
        include CIAX::List::Shell

        def ext_shell
          super(Jump)
          @cfg[:jump_site] = @jumpgrp
          sites = @cfg[:db].displist
          @jumpgrp.ext_grp.merge_items(sites)
          @current = @run_list.first
          self
        end
      end

      class Jump < LongJump; end
    end
  end
end
