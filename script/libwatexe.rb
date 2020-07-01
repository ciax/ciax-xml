#!/usr/bin/env ruby
require 'libappdic'
require 'libwatprt'

module CIAX
  # Watch Layer
  module Wat
    deep_include(CmdTree)
    # atrb must have [:dbi], [:sub_dic]
    class Exe < Exe
      def initialize(spcfg, atrb = Hashx.new)
        super
        @sub_exe = _init_sub_exe
        ___init_stat
        _opt_mode
      end

      private

      def ___init_stat
        @stat = Event.new(@dbi, @sub_exe.stat)
        @sv_stat.init_flg(auto: '&', event: '@')
        @stat_pool = StatPool.new(@stat, @sv_stat)
      end

      def _ext_remote
        super
        _remote_stat
        self
      end

      def _ext_shell
        super.input_conv_set
        @cfg[:output] = View.new(@stat).ext_prt.upd
        @cobj.loc.add_view
        self
      end

      # Local mode
      module Local
        include CIAX::Exe::Local
        def self.extended(obj)
          Msg.type?(obj, Exe)
        end

        # Mode Extention by Option
        def ext_local
          @sub_exe.pre_exe_procs << proc { |args| @stat.block?(args) }
          super
        end

        private

        def _ext_test
          @post_exe_procs << proc { @stat.update? }
          super
        end

        def _ext_driver
          super
          require 'libwatdrv'
          extend(Driver).ext_driver
        end
      end
    end

    if $PROGRAM_NAME == __FILE__
      Opt::Conf.new('[id]', options: 'cehlt') do |cfg|
        db = cfg[:db] = Ins::Db.new
        dbi = db.get(cfg.args.shift)
        sub_dic = App::ExeDic.new(cfg)
        Exe.new(cfg, dbi: dbi, sub_dic: sub_dic)
      end.cui
    end
  end
end
