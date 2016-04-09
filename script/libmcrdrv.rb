#!/usr/bin/ruby
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager Driver Module
    module Drv
      def self.extended(obj)
        Msg.type?(obj, Man)
      end

      # Initialize for driver
      def ext_driver
        @sv_stat.repl(:sid, '') # For server response
        _init_proc_pre_exe
        _init_proc_extcmd
        _init_proc_intcmd
        _init_proc_intrpt
        _init_proc_swmode
        @terminate_procs << proc { @stat.clean }
        self
      end

      alias_method :ext_test, :ext_driver

      def _init_proc_pre_exe
        @pre_exe_procs << proc do
          @sv_stat.repl(:sid, '')
          @sv_stat.flush(:list, @stat.alives)
          @sv_stat.flush(:run) if @sv_stat.get(:list).empty?
        end
      end

      # External Command Group
      def _init_proc_extcmd
        @cobj.rem.ext.def_proc do |ent|
          sid = @stat.add(ent).id
          @sv_stat.repl(:sid, sid)
          @sv_stat.push(:list, sid)
          ent.msg = 'ACCEPT'
        end
      end

      # Internal Command Group
      def _init_proc_intcmd
        @cobj.rem.int.def_proc do|ent|
          @sv_stat.repl(:sid, ent.par[0])
          ent.msg = @stat.reply(ent.id) || 'NOSID'
        end
      end

      def _init_proc_intrpt
        @cobj.get('interrupt').def_proc do |ent|
          @stat.interrupt
          ent.msg = 'INTERRUPT'
        end
      end

      def _init_proc_swmode
        @cobj.get('nonstop').def_proc do
          @sv_stat.up(:nonstop)
        end
        @cobj.get('interactive').def_proc do
          @sv_stat.dw(:nonstop)
        end
      end
    end
  end
end
