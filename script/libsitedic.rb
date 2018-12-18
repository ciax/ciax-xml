#!/usr/bin/ruby
require 'libdic'
module CIAX
  module Site
    # @cfg[:db] associated site/layer should be set
    # This should be set [:db]
    class List < CIAX::List
      attr_reader :db, :sub_list
      attr_accessor :super_list
      def initialize(super_cfg, atrb = Hashx.new)
        atrb[:opt] = super_cfg[:opt].sub_opt
        super
        @cfg[:column] = 2
        @run_list = []
      end

      def get(site)
        eobj = _list.key?(site) ? super : ___add(site)
        @sub_list.get(eobj.sub.id) if @sub_list
        eobj
      end

      def run
        verbose { "Initiate Run #{@run_list}" }
        @run_list.each { |s| get(s).run }
        @sub_list.run if @sub_list
        self
      end

      def ext_shell
        _ext_local_shell
      end

      private

      def _store_db(db)
        @db = @cfg[:db] = type?(db, Db)
        sites = @db.displist.valid_keys & (@cfg[:sites] || [])
        @run_list = sites.empty? ? @db.run_list : sites
        self
      end

      def ___add(site) # returns Exe
        # layer_module can be Frm,App,Wat,Hex
        atrb = { dbi: @db.get(site), sub_list: @sub_list }
        eobj = layer_module::Exe.new(@cfg, atrb)
        _list.put(site, eobj)
        eobj
      end

      # Shell module which is Site::List specific
      module Shell
        include CIAX::List::Shell

        def ext_local_shell
          super
          @cfg[:jump_site] = @jumpgrp
          @jumpgrp.ext_grp.merge_items(@cfg[:db].displist)
          @current = @run_list.first
          @sub_list.ext_shell if @sub_list
          self
        end

        def get(site)
          @current = site
          super
        end

        def switch(site)
          # Change top_list as well as the lower layer changed
          @super_list.switch(site) if @super_list
          super
        end
      end

      class Jump < LongJump; end
    end
  end
end
