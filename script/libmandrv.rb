#!/usr/bin/ruby
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man
      # Macro Manager Driver Module
      module Drv
        def self.extended(obj)
          Msg.type?(obj, Man)
        end

        # Initiate for driver
        def ext_local_driver
          @sv_stat.repl(:sid, '') # For server response
          ___init_pre_exe
          ___init_post_exe
          ___init_proc_rem(@cobj.rem)
          ___init_proc_loc
          @cobj.rem.ext_input_log
          @terminate_procs << proc { @stat.clean }
          self
        end

        alias ext_local_test ext_local_driver

        def ___init_pre_exe
          @pre_exe_procs << proc do
            @sv_stat.flush(:list, @stat.alives).repl(:sid, '')
            @sv_stat.flush(:run).cmt if @sv_stat.upd.get(:list).empty?
          end
        end

        def ___init_post_exe
          @post_exe_procs << proc do
            @sv_stat.get(:list).each { |id| @par.push(id) }
          end
        end

        def ___init_proc_rem(rem)
          # External Command Group
          rem.ext.def_proc do |ent|
            sid = @stat.add(ent).id
            @sv_stat.push(:list, sid).repl(:sid, sid)
          end
          # Internal Command Group
          rem.int.def_proc do |ent|
            @sv_stat.repl(:sid, ent.par[0])
            ent.msg = @stat.reply(ent.id) || 'NOSID'
          end
        end

        def ___init_proc_loc
          @cobj.get('interrupt').def_proc { @stat.interrupt }
          @cobj.get('nonstop').def_proc { @sv_stat.up(:nonstop) }
          @cobj.get('interactive').def_proc { @sv_stat.dw(:nonstop) }
        end
      end
    end
  end
end
