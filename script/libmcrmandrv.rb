#!/usr/bin/ruby
require 'libmcrexe'
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
          @rec_arc.ext_local.refresh
          @rec_arc.ext_save if @opt.mcr_log?
          @sv_stat.repl(:sid, '') # For server response
          @cobj.rem.ext_input_log
          self
        end

        # Macro Generator
        def gen_cmd(ent)
          mobj = Exe.new(ent) { |e| gen_cmd(e) }
          Msg.type?(mobj.start.thread, Threadx::Fork)
          @mcr_list.add(mobj)
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

        def ext_local_server
          verbose { 'Initiate Record Archive' }
          Threadx::Fork.new('RecArc', 'mcr', @id) do
            @rec_arc.clear.refresh
          end
          ___web_cmdlist
          super
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

        # Making Command List JSON file for WebApp
        def ___web_cmdlist
          verbose { 'Initiate JS Command List' }
          dbi = @cfg[:dbi]
          jl = Hashx.new(port: @port, commands: dbi.list, label: dbi.label)
          IO.write(vardir('json') + 'mcr_conf.js', 'var config = ' + jl.to_j)
        end
      end
    end
  end
end
