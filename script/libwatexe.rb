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
        @stat = Event.new(@dbi, @sub_exe.stat)
        @sv_stat.init_flg(auto: '&', event: '@')
        _opt_mode
      end

      # wait for busy end or status changed
      def wait_ready
        verbose { 'Waiting Busy Device' }
        100.times do
          sleep 0.1
          next if @sv_stat.upd.up?(:busy) # event from buffer
          return 'done' unless @sv_stat.up?(:comerr)
          com_err('Busy Device not responding')
        end
        com_err('Timeout for Busy Device')
      end

      private

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

    if __FILE__ == $PROGRAM_NAME
      Opt::Conf.new('[id]', options: 'cehlt') do |cfg|
        db = cfg[:db] = Ins::Db.new
        dbi = db.get(cfg.args.shift)
        Exe.new(cfg, dbi: dbi, sub_dic: App::ExeDic.new(cfg))
      end.cui
    end
  end
end
