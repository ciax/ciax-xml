#!/usr/bin/ruby
require 'libman'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man
      def ext_local_processor
        @mode = @opt.dry? ? 'DRY' : 'PRCS'
        extend(Processor).ext_local_processor
      end

      # Macro Manager Processing Module
      module Processor
        def self.extended(obj)
          Msg.type?(obj, Man)
        end

        # Initiate for driver
        def ext_local_processor
          ___init_seq
          @rec_list.ext_save if @opt.mcr_log?
          @sv_stat.repl(:sid, '') # For server response
          @sub_list = @cobj.rem.ext.dev_list if @opt.drv?
          @cobj.rem.ext_input_log
          self
        end

        def run
          ext_local_server if @opt.sv?
          @sub_list.run if @sub_list
          super
        end

        private

        def ___init_seq
          @seq_list = SeqList.new(@rec_list)
          ___init_pre_exe
          ___init_proc_rem_ext
          ___init_proc_rem_int
          ___init_proc_rem_sys
        end

        def ___init_pre_exe
          @pre_exe_procs << proc do
            @sv_stat.flush(:list, @seq_list.alives).repl(:sid, '')
            @sv_stat.flush(:run).cmt if @sv_stat.upd.get(:list).empty?
            @stat.upd
          end
        end

        def ___init_proc_rem_ext
          # External Command Group
          ext = @cobj.rem.ext
          ext.def_proc do |ent|
            sid = @seq_list.add(ent).id
            @sv_stat.push(:list, sid).repl(:sid, sid)
          end
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
