#!/usr/bin/ruby
require 'libapplist'
require 'libwatprt'

module CIAX
  # Watch Layer
  module Wat
    deep_include(CmdTree)
    # cfg must have [:dbi], [:sub_list]
    class Exe < Exe
      attr_reader :sub, :stat
      def initialize(cfg, atrb = Hashx.new)
        super
        _init_with_dbi
        _init_takeover
        @stat = Event.new(@sub.id)
        @host = @sub.host
        _opt_mode
      end

      def ext_shell
        super
        @cfg[:output] = View.new(@stat).ext_prt
        @cobj.loc.add_view
        input_conv_set
        self
      end

      private

      # Mode Extention by Option
      def ext_local
        _init_upd_
        @sub.pre_exe_procs << proc { |args| @stat.block?(args) }
        @stat.ext_local_rsp(@sub.stat, @sv_stat)
        super
      end

      def ext_local_test
        @post_exe_procs << proc { @stat.update? }
        super
      end

      def ext_local_driver
        require 'libwatdrv'
        super
      end

      # Sub methods for Initialize
      def _init_takeover
        @sub = @cfg[:sub_list].get(@id)
        @sv_stat = @sub.sv_stat.init_flg(auto: '&', event: '@')
        @cobj.add_rem(@sub.cobj.rem)
        @mode = @sub.mode
        @post_exe_procs.concat(@sub.post_exe_procs)
      end

      def _init_upd_
        @stat.cmt_procs << proc do |ev|
          verbose { 'Propagate Event#cmt -> Watch#(set blocking command)' }
          block = ev.get(:block).map { |id, par| par ? nil : id }.compact
          @cobj.rem.ext.valid_sub(block)
        end
      end

      def _init_auto_thread_
        Threadx::Loop.new('Regular', 'wat', @id) do
          @stat.auto_exec
          sleep 10
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehlts') do |cfg, args|
        db = cfg[:db] = Ins::Db.new
        dbi = db.get(args.shift)
        atrb = { dbi: dbi, sub_list: App::List.new(cfg) }
        Exe.new(cfg, atrb).ext_shell.shell
      end
    end
  end
end
