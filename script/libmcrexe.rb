#!/usr/bin/env ruby
require 'libexe'
require 'libseq'
require 'libthreadx'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Executor
    # Local mode only
    class Exe < Exe
      attr_reader :thread, :seq
      def initialize(spcfg, atrb = Hashx.new, &submcr_proc)
        super
        verbose { 'Initiate New Macro' }
        ___init_cmd
        @sv_stat = type?(@cfg[:sv_stat], Prompt)
        ___init_seq(submcr_proc)
        _ext_local
      end

      def interrupt
        exe(['interrupt'], 'local', 0)
        self
      end

      private

      # Mode Extention by Option
      def _ext_shell
        super
        @prompt_proc = proc { opt_listing(@valid_keys) }
        @cobj.loc.add_view
        self
      end

      def ___init_cmd
        rem = @cobj.add_rem
        rem.cfg[:def_msg] = 'ACCEPT'
        @sys = rem.add_sys
        @int = rem.add_int
        @sys.add_form('run', 'seqence').def_proc { run }
        @valid_keys = @cfg[:valid_keys] = @int.valid_keys.clear
        @valid_keys << 'run'
      end

      def ___init_seq(submcr_proc)
        @seq = Sequencer.new(@cfg, &submcr_proc)
        @id = @seq.id
        @int.def_proc { |ent| @seq.reply(ent.id) }
        @stat = @seq.record
      end

      # To inhelit CIAX::Exe::Local
      module Local
        include CIAX::Exe::Local
        def self.extended(obj)
          Msg.type?(obj, Exe)
        end

        # Mode Extension by Option
        def ext_local
          _set_def_proc('interrupt') { @thread.raise(Interrupt) }
          super
        end

        def run
          @thread = Threadx::Fork.new('Macro', 'seq', @id) do
            @sys.valid_keys.delete('run')
            @seq.play
          end
          self
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Conf.new('[proj] [cmd] (par)', options: 'edlnr') do |cfg|
        ent = Index.new(cfg).add_rem.add_ext.set_cmd(cfg.args)
        Exe.new(ent).shell
      end
    end
  end
end
