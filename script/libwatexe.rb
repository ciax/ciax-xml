#!/usr/bin/ruby
require 'libapplist'
require 'libwatview'

module CIAX
  # Watch Layer
  module Wat
    # cfg must have [:db], [:sub_list]
    class Exe < Exe
      attr_reader :sub, :stat
      def initialize(id, cfg, atrb = {})
        super(id, cfg, atrb)
        _init_prompt.add_flg(auto: '&', event: '@')
        @cobj.add_rem(@sub.cobj.rem)
        @stat = Event.new(@sub.id)
        @host = @sub.host
        _opt_mode
      end

      def join(src = 'local')
        100.times do
          sleep 0.1
          @server_upd_proc.call(src) if @server_upd_proc
          return true unless @sv_stat.get(:busy)
        end
        false
      end

      def ext_shell
        super
        @cfg[:output] = View.new(@stat)
        @cobj.loc.add_view
        input_conv_set
        self
      end

      private

      def ext_client
        @server_upd_proc = proc { |src| exe([], src, 2) }
        super
      end

      def ext_test
        ext_non_client
        @post_exe_procs << proc { @stat.next_upd }
        super
      end

      def ext_driver
        ext_non_client
        @stat.ext_file.auto_save
        # @stat[:int] is overwritten by initial loading
        @sub.batch_interrupt = @stat.get(:int)
        @stat.ext_log if @cfg[:option].log?
        _init_upd_drv_
        @tid_auto = _init_auto_thread_
        @sub.post_exe_procs << proc do
          @sv_stat.put(:auto, @tid_auto && @tid_auto.alive?)
        end
        super
      end

      def ext_non_client
        _init_upd_
        @sub.pre_exe_procs << proc { |args| @stat.block?(args) }
        @stat.ext_rsp(@sub.stat, @sv_stat)
        self
      end

      def _init_upd_
        @stat.post_upd_procs << proc do|ev|
          verbose { 'Propagate Event#upd -> Watch#upd' }
          block = ev.get(:block).map { |id, par| par ? nil : id }.compact
          @cobj.rem.ext.valid_sub(block)
        end
      end

      def _init_upd_drv_
        @stat.post_upd_procs << proc do|ev|
          ev.get(:exec).each do|src, pri, args|
            verbose { "Exec:#{args} by Condition from [#{src}] by [#{pri}]" }
            @sub.exe(args, src, pri)
            sleep ev.interval
          end.clear
        end
      end

      def _init_auto_thread_
        @stat.next_upd
        ThreadLoop.new("Watch:Regular(#{@id})", 14) do
          @stat.auto_exec.upd.sleep
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
