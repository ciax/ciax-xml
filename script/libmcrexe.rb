#!/usr/bin/ruby
require 'libexe'
require 'libseq'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Exe < Exe
      attr_reader :thread, :seq
      def initialize(super_cfg, atrb = Hashx.new, &submcr_proc)
        super
        verbose { 'Initiate New Macro' }
        ___init_cmd
        ___init_seq(submcr_proc)
        @sv_stat = type?(@cfg[:sv_stat], Prompt)
        ___init_rem_sys
        _ext_local
        @mode = @opt.drv? ? 'DRV' : 'TEST'
      end

      def interrupt
        @thread.raise(Interrupt)
        self
      end

      def run
        @thread = Msg.type?(@seq.fork, Threadx::Fork)
        self
      end

      # Mode Extention by Option
      def ext_local_shell
        extend(Shell).ext_local_shell
        @prompt_proc = proc { @sv_stat.to_s + opt_listing(@int.valid_keys) }
        @cobj.loc.add_view
        self
      end

      private

      def ___init_cmd
        rem = @cobj.add_rem
        rem.cfg[:def_msg] = 'ACCEPT'
        rem.add_sys
        @int = rem.add_int
        @cfg[:valid_keys] = @int.valid_keys.clear
      end

      def ___init_seq(submcr_proc)
        @seq = Sequencer.new(@cfg, &submcr_proc)
        @id = @seq.id
        @int.def_proc { |ent| @seq.reply(ent.id) }
        @stat = @seq.record
      end

      def ___init_rem_sys
        @cobj.get('interrupt').def_proc { interrupt }
        @cobj.get('nonstop').def_proc { @sv_stat.up(:nonstop) }
        @cobj.get('interactive').def_proc { @sv_stat.dw(:nonstop) }
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', options: 'eldnr') do |cfg, args|
        ent = Index.new(cfg).add_rem.add_ext.set_cmd(args)
        Exe.new(ent).run.shell
      end
    end
  end
end
