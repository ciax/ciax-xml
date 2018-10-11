#!/usr/bin/ruby
require 'libseqlist'
require 'libman'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man
      def ext_local_processor
        @mode = @opt.dry? ? 'DRY' : 'PRCS'
        extend(Processor).ext_local_processor
        _ext_local
      end

      # Macro Manager Processing Module
      module Processor
        def self.extended(obj)
          Msg.type?(obj, Man)
        end

        # Initiate for driver
        def ext_local_processor
          @rec_list.ext_local
          @rec_list.rec_arc.auto_save if @opt.mcr_log?
          @seq_list = SeqList.new(@rec_list)
          @sv_stat.repl(:sid, '') # For server response
          ___init_pre_exe
          ___init_proc_rem_ext
          ___init_proc_rem_int
          ___init_proc_loc
          @cobj.rem.ext_input_log
          self
        end

        def run
          @sub_list.run
          super
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
          @sub_list = ext.dev_list
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

        def ___init_proc_loc
          @cobj.get('interrupt').def_proc { @seq_list.interrupt }
          @cobj.get('nonstop').def_proc { @sv_stat.up(:nonstop) }
          @cobj.get('interactive').def_proc { @sv_stat.dw(:nonstop) }
        end
      end
    end
  end
end
