#!/usr/bin/env ruby
require 'libmcrexe'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man
      # Macro Manager Processing Module (TEST or DRIVE mode)
      module Processor
        def self.extended(obj)
          Msg.type?(obj, Man)
        end

        # Initiate for driver
        def ext_local_processor
          # For jump_mcr
          @cfg[:cid] = 'manager'
          @mode = @opt.dry? ? 'DRY' : 'PRCS'
          @mcr_dic = @cfg[:mcr_dic] || Hashx.new
          @stat.ext_local.refresh
          @sv_stat.repl(:sid, '') # For server response
          ___init_log
          ___init_procs
          self
        end

        # Macro Generator
        def gen_cmd(ent)
          mobj = Exe.new(ent) { |e| gen_cmd(e) }
          @mcr_dic.put(mobj.id, mobj.run)
          @stat.push(mobj.stat)
          mobj
        end

        # Macro Manipulator
        def man_cmd(ent)
          id = ent.par[0]
          mobj = @mcr_dic.get(id)
          @sv_stat.repl(:sid, id)
          ent.msg = mobj.exe([ent[:id]]).to_s || 'NOSID'
          mobj
        end

        private

        def ___init_log
          return unless @opt.mcr_log?
          @stat.ext_save
          @cobj.rem.ext_input_log
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
          end
        end

        def ___init_proc_def
          rem = @cobj.rem
          rem.ext.def_proc { |ent| gen_cmd(ent) }
          rem.int.def_proc { |ent| man_cmd(ent) }
        end

        def ___init_proc_sys
          @cobj.get('interrupt').def_proc do
            @mcr_dic.each { |k, v| k =~ /[\d]+/ && v.interrupt }
          end
        end
      end
    end
  end
end
