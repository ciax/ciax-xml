#!/usr/bin/ruby
require 'libman'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man
      def ext_local_processor(mcr_dic)
        extend(Processor).ext_local_processor(mcr_dic)
      end
      # Macro Manager Processing Module (TEST or DRIVE mode)
      module Processor
        def self.extended(obj)
          Msg.type?(obj, Man)
        end

        # Initiate for driver
        def ext_local_processor(mcr_dic)
          @mode = @opt.dry? ? 'DRY' : 'PRCS'
          @mcr_dic = type?(mcr_dic, Dic)
          ___init_stat
          ___init_procs
          @sv_stat.repl(:sid, '') # For server response
          @cobj.rem.ext_input_log
          self
        end

        # Macro Generator
        def gen_cmd(ent)
          @mcr_dic.add(ent)
        end

        # Macro Manipulator
        def man_cmd(ent)
          mobj = @mcr_dic.get(ent.par[0])
          ent.msg = mobj.exe([ent[:id]]).to_s || 'NOSID'
          mobj
        end

        private

        def ___init_stat
          @stat.ext_local.refresh
          @stat.ext_save if @opt.mcr_log?
        end

        def ___init_procs
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
          @cobj.get('interrupt').def_proc { @mcr_dic.interrupt }
          @cobj.get('nonstop').def_proc { @sv_stat.up(:nonstop) }
          @cobj.get('interactive').def_proc { @sv_stat.dw(:nonstop) }
        end
      end
    end
  end
end
