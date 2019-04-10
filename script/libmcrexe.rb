#!/usr/bin/env ruby
require 'libexe'
require 'libseq'
require 'libthreadx'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    # Local mode only
    class Exe < Exe
      attr_reader :thread, :seq
      def initialize(spcfg, atrb = Hashx.new, &submcr_proc)
        super
        verbose { 'Initiate New Macro' }
        ___init_cmd
        @submcr_proc = submcr_proc
        @sv_stat = type?(@cfg[:sv_stat], Prompt)
        @cobj.get('interrupt').def_proc { interrupt }
        @stat = Record.new
        _opt_mode
      end

      def interrupt
        @thread.raise(Interrupt)
        self
      end

      private

      # Mode Extention by Option
      def _ext_local_shell
        super
        @prompt_proc = proc { opt_listing(@int.valid_keys) }
        @cobj.loc.add_view
        self
      end

      def ___init_cmd
        rem = @cobj.add_rem
        rem.cfg[:def_msg] = 'ACCEPT'
        rem.add_sys
        @int = rem.add_int
        @cfg[:valid_keys] = @int.valid_keys.clear
      end

      # Local mode
      module Local
        include CIAX::Exe::Local
        def self.extended(obj)
          Msg.type?(obj, Exe)
        end

        def ext_local
          @seq = Sequencer.new(@cfg, &@submcr_proc)
          @id = @seq.id
          @int.def_proc { |ent| @seq.reply(ent.id) }
          @stat = @seq.record
          super
        end

        def run
          @thread = Threadx::Fork.new('Macro', 'seq', @id) { @seq.play }
          self
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', options: 'edlnsr') do |cfg|
        ent = Index.new(cfg, Atrb.new(cfg)).add_rem.add_ext.set_cmd(cfg.args)
        mexe = Exe.new(ent)
        cfg.opt.sh? ? mexe.run.shell : mexe.seq.play
      end
    end
  end
end
