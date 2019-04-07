#!/usr/bin/env ruby
require 'libappdic'
require 'libwatprt'

module CIAX
  # Watch Layer
  module Wat
    deep_include(CmdTree)
    # atrb must have [:dbi], [:sub_dic]
    class Exe < Exe
      attr_reader :sub, :stat
      def initialize(spcfg, atrb = Hashx.new)
        super
        dbi = _init_dbi2cfg
        @stat = Event.new(dbi, ___init_sub)
        @host = @sub.host
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

      def _ext_local_shell
        super.input_conv_set
        @cfg[:output] = View.new(@stat).ext_prt.upd
        @cobj.loc.add_view
        self
      end

      # Sub methods for Initialize
      def ___init_sub
        @sub = @cfg[:sub_dic].get(@id)
        @sv_stat = @sub.sv_stat.init_flg(auto: '&', event: '@')
        @cobj.add_rem(@sub.cobj.rem)
        @mode = @sub.mode
        @post_exe_procs.concat(@sub.post_exe_procs)
        @sub.stat
      end

      # Local mode
      module Local
        include CIAX::Exe::Local
        def self.extended(obj)
          Msg.type?(obj, Exe)
        end

        # Mode Extention by Option
        def _ext_local
          @sub.pre_exe_procs << proc { |args| @stat.block?(args) }
          super
        end

        def _ext_local_test
          @post_exe_procs << proc { @stat.update? }
          super
        end

        def _ext_local_driver
          super
          require 'libwatdrv'
          extend(Driver).ext_local_driver
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehlts') do |cfg|
        db = cfg[:db] = Ins::Db.new
        dbi = db.get(cfg.args.shift)
        atrb = { dbi: dbi, sub_dic: App::ExeDic.new(cfg) }
        eobj = Exe.new(cfg, atrb)
        if cfg.opt.sh?
          eobj.shell
        else
          puts eobj.exe(cfg.args).stat
        end
      end
    end
  end
end
