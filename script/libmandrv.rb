#!/usr/bin/ruby
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager Driver Module
    module ManDrv
      def self.extended(obj)
        Msg.type?(obj, Man)
      end

      # Initiate for driver
      def ext_driver
        @sv_stat.repl(:sid, '') # For server response
        _init_proc_pre_exe
        _init_proc_post_exe
        _init_proc_extcmd
        _init_proc_intcmd
        _init_proc_intrpt
        _init_proc_swmode
        _init_dev
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

      def _init_proc_post_exe
        @post_exe_procs << proc do
          (@sv_stat.get(:list) - @par.list).each { |id| @par.add(id) }
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
        @cobj.get('interrupt').def_proc { @stat.interrupt }
      end

      def _init_proc_swmode
        @cobj.get('nonstop').def_proc { @sv_stat.up(:nonstop) }
        @cobj.get('interactive').def_proc { @sv_stat.dw(:nonstop) }
      end

      def _init_dev
        @cfg[:sites].each { |site| @cfg[:dev_list].get(site) }
      end
    end
  end
end
