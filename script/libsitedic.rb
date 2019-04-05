#!/usr/bin/env ruby
require 'libexedic'
module CIAX
  module Site
    # @cfg[:db] associated site/layer should be set
    # This should be set [:db]
    class ExeDic < CIAX::ExeDic
      attr_reader :db, :sub_dic
      attr_accessor :super_dic
      def initialize(spcfg, atrb = Hashx.new)
        atrb[:opt] = spcfg[:opt].sub_opt
        super
        @cfg[:column] = 2
        @run_list = []
      end

      def get(site)
        _dic.key?(site) ? super : ___add(site)
      end

      def run
        verbose { "Initiate Run #{@run_list.inspect}" }
        @run_list.each { |s| get(s).run }
        self
      end

      private

      def _store_db(db)
        @db = @cfg[:db] = type?(db, Db)
        self
      end

      # Making run_list
      def _mk_runlist
        valid = @db.disp_dic.valid_keys
        sites = @cfg[:sites]
        @run_list = sites ? (sites & valid) : @db.run_list
        self
      end

      def ___add(site) # returns Exe
        # layer_module can be Frm,App,Wat,Hex
        atrb = { dbi: @db.get(site), sub_dic: @sub_dic }
        eobj = layer_module::Exe.new(@cfg, atrb)
        put(site, eobj)
        eobj
      end

      # Shell module which is Site::ExeDic specific
      module Shell
        include CIAX::ExeDic::Shell

        def ext_local_shell
          super
          @cfg[:jump_site] = @jumpgrp
          @jumpgrp.ext_grp.merge_items(@cfg[:db].disp_dic)
          @current = @run_list.first
          @sub_dic.ext_local_shell if @sub_dic
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
