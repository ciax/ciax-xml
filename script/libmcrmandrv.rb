#!/usr/bin/ruby
require 'libmcrman'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man
      # Macro Manager Processing Module (TEST or DRIVE mode)
      module Driver
        def self.extended(obj)
          Msg.type?(obj, Man)
        end

        # Initiate for driver
        def ext_local_driver
          @mode = @opt.dry? ? 'DRY' : 'PRCS'
          @mcr_list = type?(@cfg[:mcr_list], List)
          ___init_procs
          @sv_stat.repl(:sid, '') # For server response
          @cobj.rem.ext_input_log
          self
        end

        # Macro Generator
        def gen_cmd(ent)
          mobj = @mcr_list.add(ent)
          @stat.push(mobj.stat)
          mobj
        end

        # Macro Manipulator
        def man_cmd(ent)
          @sv_stat.repl(:sid, ent.par[0])
          mobj = @mcr_list.get(ent.par[0])
          ent.msg = mobj.exe([ent[:id]]) || 'NOSID'
          mobj
        end

        private

        def ___init_procs
          @stat.ext_local
          ___init_pre_exe
          ___init_proc_def
          ___init_proc_sys
        end

        def ___init_pre_exe
          @pre_exe_procs << proc do
            @sv_stat.repl(:sid, '')
            @sv_stat.flush(:run).cmt if @sv_stat.get(:list).empty?
            @stat.upd
          end
        end

        def ___init_proc_def
          rem = @cobj.rem
          rem.ext.def_proc { |ent| gen_cmd(ent) }
          rem.int.def_proc { |ent| man_cmd(ent) }
        end

        def ___init_proc_sys
          @cobj.get('interrupt').def_proc { @cfg[:mcr_list].interrupt }
          @cobj.get('nonstop').def_proc { @sv_stat.up(:nonstop) }
          @cobj.get('interactive').def_proc { @sv_stat.dw(:nonstop) }
        end
      end
    end
  end
end
