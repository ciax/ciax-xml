#!/usr/bin/ruby
require 'libappexe'
require 'libwatview'

module CIAX
  # Watch Layer
  module Wat
    # cfg should have [:sub_list]
    class Exe < Exe
      attr_reader :sub, :stat
      def initialize(id, cfg)
        super(id, cfg)
        @sub = @cfg[:sub_list].get(@id)
        @cobj.add_rem(@sub.cobj.rem)
        @stat = Event.new.setdbi(@dbi)
        @sv_stat = @sub.sv_stat.add_db(auto: '&', event: '@')
        @sub.batch_interrupt = @stat.get('int')
        @mode = @sub.mode
        @host = @sub.host
        opt_mode
      end

      def ext_shell
        super
        @cfg[:output] = View.new(@stat)
        @cobj.loc.add_view
        input_conv_set
        self
      end

      private

      def ext_test
        ext_non_client
        @post_exe_procs << proc { @stat.next_upd }
        self
      end

      def ext_non_client
        @stat.post_upd_procs << proc do|ev|
          verbose { 'Propagate Event#upd -> Watch#upd' }
          block = ev.get('block').map { |id, par| par ? nil : id }.compact
          @cobj.rem.ext.valid_sub(block)
        end
        @sub.pre_exe_procs << proc { |args| @stat.block?(args) }
        @stat.ext_rsp(@sub.stat, @sv_stat)
        self
      end

      def ext_driver
        ext_non_client
        @stat.ext_file.auto_save
        @stat.ext_log if OPT[:e]
        @stat.post_upd_procs << proc do|ev|
          ev.get('exec').each do|src, pri, args|
            verbose { "Executing:#{args} in accordance with Condition from [#{src}] by [#{pri}]" }
            @sub.exe(args, src, pri)
            sleep ev.interval
          end.clear
        end
        @tid_auto = auto_update
        @sub.post_exe_procs << proc do
          @sv_stat.put(:auto, @tid_auto && @tid_auto.alive?)
        end
        self
      end

      def auto_update
        @stat.next_upd
        ThreadLoop.new("Watch:Regular(#{@id})", 14) do
          @stat.upd.auto_exec.sleep
        end
      end
    end

    # Watch List
    class List < Site::List
      def initialize(cfg, top_list = nil)
        super(cfg, top_list || self, App::List)
        store_db(@sub_list.db)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('ceh:lts')
      cfg = Config.new
      cfg[:jump_groups] = []
      cfg[:site] = ARGV.shift
      begin
        List.new(cfg).ext_shell.shell
      rescue InvalidID
        OPT.usage('(opt) [id]')
      end
    end
  end
end
