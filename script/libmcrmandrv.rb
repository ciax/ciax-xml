#!/usr/bin/ruby
require 'libseqlist'

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
          ___init_seq
          @stat.ext_save if @opt.mcr_log?
          @sv_stat.repl(:sid, '') # For server response
          @cobj.rem.ext_input_log
          self
        end

        def run
          ext_local_server if @opt.sv?
          super
        end

        private

        def ___init_seq
          @seq_list = SeqList.new(@cfg) { |rec| @stat.push(rec) }
          @stat.ext_local
          ___init_pre_exe
          ___init_proc_rem_ext
          ___init_proc_rem_int
          ___init_proc_rem_sys
        end

        def ___init_pre_exe
          @pre_exe_procs << proc do
            @sv_stat.upd
            @sv_stat.flush(:run).cmt if @sv_stat.upd.get(:list).empty?
            @stat.upd
          end
        end

        def ___init_proc_rem_ext
          # External Command Group
          ext = @cobj.rem.ext
          ext.def_proc { |ent| @seq_list.add(ent) }
        end

        def ___init_proc_rem_int
          # Internal Command Group
          @cobj.rem.int.def_proc do |ent|
            @sv_stat.repl(:sid, ent.par[0])
            ent.msg = @seq_list.reply(ent.id) || 'NOSID'
          end
        end

        def ___init_proc_rem_sys
          @cobj.get('interrupt').def_proc { @seq_list.interrupt }
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
