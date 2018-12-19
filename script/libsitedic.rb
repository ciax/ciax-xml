#!/usr/bin/ruby
require 'libdic'
module CIAX
  module Site
    # @cfg[:db] associated site/layer should be set
    # This should be set [:db]
    class Dic < CIAX::Dic
      attr_reader :db, :sub_dic
      attr_accessor :super_dic
      def initialize(super_cfg, atrb = Hashx.new)
        atrb[:opt] = super_cfg[:opt].sub_opt
        super
        @cfg[:column] = 2
        @run_list = []
      end

      def get(site)
        eobj = _dic.key?(site) ? super : ___add(site)
        @sub_dic.get(eobj.sub.id) if @sub_dic
        eobj
      end

      def run
        verbose { "Initiate Run #{@run_list.inspect}" }
        @run_list.each { |s| get(s).run }
        @sub_dic.run if @sub_dic
        self
      end

      def ext_shell
        _ext_local_shell
      end

      private

      def _store_db(db)
        @db = @cfg[:db] = type?(db, Db)
        sites = @db.disp_dic.valid_keys & (@cfg[:sites] || [])
        @run_list = sites.empty? ? @db.run_list : sites
        self
      end

      def ___add(site) # returns Exe
        # layer_module can be Frm,App,Wat,Hex
        atrb = { dbi: @db.get(site), sub_dic: @sub_dic }
        eobj = layer_module::Exe.new(@cfg, atrb)
        _dic.put(site, eobj)
        eobj
      end

      # Shell module which is Site::Dic specific
      module Shell
        include CIAX::Dic::Shell

        def ext_local_shell
          super
          @cfg[:jump_site] = @jumpgrp
          @jumpgrp.ext_grp.merge_items(@cfg[:db].disp_dic)
          @current = @run_list.first
          @sub_dic.ext_shell if @sub_dic
          self
        end

        def get(site)
          @current = site
          super
        end

        def switch(site)
          # Change super_dic as well as the lower layer changed
          @super_dic.switch(site) if @super_dic
          super
        end
      end

      class Jump < LongJump; end
    end
  end
end
