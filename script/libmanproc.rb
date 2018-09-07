#!/usr/bin/ruby
require 'libseqlist'
require 'libman'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man
      def ext_local_processor
        @mode = @cfg[:opt].dry? ? 'DRY' : 'PRCS'
        extend(Processor).ext_local_processor
        _ext_local
      end

      private

      def _work?(opt)
        return unless opt.prcs?
        ext_local_processor
      end

      # Macro Manager Processing Module
      module Processor
        def self.extended(obj)
          Msg.type?(obj, Man)
        end

        # Initiate for driver
        def ext_local_processor
          @seq_list = SeqList.new(@cfg[:rec_arc])
          @sv_stat.repl(:sid, '') # For server response
          @stat.ext_local
          ___init_pre_exe
          ___init_proc_rem_ext
          ___init_proc_rem_int
          ___init_proc_loc
          @cobj.rem.ext_input_log
          self
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
          @cobj.rem.ext.def_proc do |ent|
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