#!/usr/bin/ruby
require 'libappdic'
require 'libwatviewprt'

module CIAX
  # Watch Layer
  module Wat
    deep_include(CmdTree)
    # atrb must have [:dbi], [:sub_dic]
    class Exe < Exe
      attr_reader :sub, :stat
      def initialize(super_cfg, atrb = Hashx.new)
        super
        dbi = _init_dbi2cfg
        ___init_sub
        @stat = Event.new(dbi)
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

      # Mode Extention by Option
      def _ext_local
        @stat.ext_local_file
        ___init_cmd_procs
        @sub.pre_exe_procs << proc { |args| @stat.block?(args) }
        super
      end

      def _ext_local_shell
        super.input_conv_set
        @cfg[:output] = View.new(@stat).ext_prt
        @cobj.loc.add_view
        self
      end

      def _ext_local_test
        @post_exe_procs << proc { @stat.update? }
        super
      end

      def _ext_local_driver
        require 'libwatdrv'
        extend(Driver).ext_local_driver
        super
      end

      # Sub methods for Initialize
      def ___init_sub
        @sub = @cfg[:sub_dic].get(@id)
        @sv_stat = @sub.sv_stat.init_flg(auto: '&', event: '@')
        @cobj.add_rem(@sub.cobj.rem)
        @mode = @sub.mode
        @post_exe_procs.concat(@sub.post_exe_procs)
      end

      def ___init_cmd_procs
        @stat.cmt_procs << proc do |ev|
          verbose { 'Propagate Event#cmt -> Watch#(set blocking command)' }
          block = ev.get(:block).map { |id, par| par ? nil : id }.compact
          @cobj.rem.ext.valid_sub(block)
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehlts') do |cfg, args|
        db = cfg[:db] = Ins::Db.new
        dbi = db.get(args.shift)
        atrb = { dbi: dbi, sub_dic: App::Dic.new(cfg) }
        Exe.new(cfg, atrb).shell
      end
    end
  end
end
