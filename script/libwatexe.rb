#!/usr/bin/ruby
require 'libapplist'
require 'libwatprt'

module CIAX
  # Watch Layer
  module Wat
    # cfg must have [:db], [:sub_list]
    class Exe < Exe
      attr_reader :sub, :stat
      def initialize(id, cfg, atrb = Hashx.new)
        super(id, cfg, atrb)
        @sub = @cfg[:sub_list].get(id)
        @sv_stat = @sub.sv_stat.add_flg(auto: '&', event: '@')
        @cobj.add_rem(@sub.cobj.rem)
        @stat = Event.new(@sub.id)
        @host = @sub.host
        _opt_mode
      end

      def ext_shell
        super
        @cfg[:output] = View.new(@stat).extend(Prt)
        @cobj.loc.add_view
        input_conv_set
        self
      end

      private

      def ext_test
        @post_exe_procs << proc { @stat.next_upd }
        super
      end

      def ext_driver
        @stat.ext_file.auto_save
        # @stat[:int] is overwritten by initial loading
        @sub.batch_interrupt = @stat.get(:int)
        @stat.ext_log if @cfg[:option].log?
        _init_upd_drv_
        _init_exe_drv_
        super
      end

      def _non_client
        _init_upd_
        @sub.pre_exe_procs << proc { |args| @stat.block?(args) }
        @stat.ext_rsp(@sub.stat, @sv_stat)
        super
      end

      def _init_upd_
        @stat.cmt_procs << proc do|ev|
          verbose { 'Propagate Event#cmt -> Watch#(set block)' }
          block = ev.get(:block).map { |id, par| par ? nil : id }.compact
          @cobj.rem.ext.valid_sub(block)
        end
      end

      def _init_upd_drv_
        @stat.cmt_procs << proc do|ev|
          ev.get(:exec).each do|src, pri, args|
            verbose { "Exec:#{args} by Condition from [#{src}] by [#{pri}]" }
            @sub.exe(args, src, pri)
            sleep ev.interval
          end.clear
        end
      end

      def _init_exe_drv_
        @tid_auto = _init_auto_thread_ unless @cfg[:cmd_line_mode]
        @sub.post_exe_procs << proc do
          @sv_stat.set_flg(:auto, @tid_auto && @tid_auto.alive?)
        end
      end

      def _init_auto_thread_
        @stat.next_upd
        ThreadLoop.new("Watch:Regular(#{@id})", 14) do
          @stat.auto_exec.sleep.upd
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', 'ceh:lts') do |cfg, args|
        atrb = { db: Ins::Db.new, sub_list: App::List.new(cfg) }
        Exe.new(args.shift, cfg, atrb).ext_shell.shell
      end
    end
  end
end
