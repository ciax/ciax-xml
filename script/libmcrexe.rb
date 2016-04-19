#!/usr/bin/ruby
require 'libseq'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Shell interface for Sequencer
    class Exe < CIAX::Exe
      attr_reader :th_mcr, :seq
      # ment should have [:sequence]'[:dev_list],[:submcr_proc]
      def initialize(ment, pid = '0')
        cfg = Config.new
        super(type?(ment, Cmd::Entity).id, cfg)
        _init_cmd_(ment, pid)
        _init_thread_
        self
      end

      def ext_shell
        super
        @prompt_proc = proc { @seq.to_v }
        @cfg[:output] = @seq.record
        @cobj.loc.add_view
        self
      end

      private

      def _init_cmd_(ment, pid)
        @cobj.add_rem.add_sys
        int = @cobj.rem.add_int(Int)
        @seq = Sequencer.new(ment, pid, int.valid_keys.clear)
        int.def_proc { |ent| ent.msg = @seq.reply(ent.id) }
        @sv_stat = @seq.sv_stat
      end

      # For Thread mode
      def _init_thread_
        @th_mcr = @seq.fork
        # interrupt is in rem.hid group
        @cobj.get('interrupt').def_proc do
          @th_mcr.raise(Interrupt)
          ent.msg = 'INTERRUPT'
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', 'cenr') do |cfg, args|
        mobj = Index.new(Conf.new(cfg))
        mobj.add_rem.add_ext(Ext)
        ent = mobj.set_cmd(args)
        Exe.new(ent).ext_shell.shell
      end
    end
  end
end
