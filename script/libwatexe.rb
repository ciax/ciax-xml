#!/usr/bin/ruby
require 'libapplist'
require 'libwatprt'

module CIAX
  # Watch Layer
  module Wat
    # cfg must have [:dbi], [:sub_list]
    class Exe < Exe
      attr_reader :sub, :stat
      def initialize(cfg, atrb = Hashx.new)
        super
        _init_dbi
        _init_takeover
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

      def ext_local_test
        @post_exe_procs << proc { @stat.next_upd }
        super
      end

      def ext_local_driver
        super
        @stat.ext_local_file.auto_save
        # @stat[:int] is overwritten by initial loading
        @sub.batch_interrupt = @stat.get(:int)
        @stat.ext_local_log if @cfg[:option].log?
        _init_upd_drv_
        _init_exe_drv_
        self
      end

      def ext_local
        _init_upd_
        @sub.pre_exe_procs << proc { |args| @stat.block?(args) }
        @stat.ext_local_rsp(@sub.stat, @sv_stat)
        super
      end

      def _init_takeover
        @sub = @cfg[:sub_list].get(@id)
        @sv_stat = @sub.sv_stat.add_flg(auto: '&', event: '@')
        @cobj.add_rem(@sub.cobj.rem)
        @mode = @sub.mode
        @post_exe_procs.concat(@sub.post_exe_procs)
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
            verbose { "Propagate Exec:#{args} from [#{src}] by [#{pri}]" }
            @sub.exe(args, src, pri)
            sleep ev.interval
          end.clear
        end
      end

      def _init_exe_drv_
        @th_auto = _init_auto_thread_ unless @cfg[:cmd_line_mode]
        @sub.post_exe_procs << proc do
          @sv_stat.set_flg(:auto, @th_auto && @th_auto.alive?)
        end
      end

      def _init_auto_thread_
        @stat.next_upd
        Threadx::Loop.new('Regular', 'wat', @id) do
          @stat.auto_exec.sleep.upd
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', 'ceh:lts') do |cfg, args|
        db = cfg[:db] = Ins::Db.new
        dbi = db.get(args.shift)
        atrb = { dbi: dbi, sub_list: App::List.new(cfg) }
        Exe.new(cfg, atrb).run.ext_shell.shell
      end
    end
  end
end
