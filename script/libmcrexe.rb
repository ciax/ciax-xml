#!/usr/bin/ruby
require 'libexe'
require 'libseq'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Exe < Exe
      attr_reader :thread, :seq
      def initialize(super_cfg, &submcr_proc)
        super(super_cfg)
        verbose { 'Initiate New Macro' }
        _init_dbi2cfg
        @sv_stat = (@cfg[:sv_stat] ||= Prompt.new(@id, @opt))
        ___init_cmd
        ___init_seq(submcr_proc)
      end

      # Mode Extention by Option

      def ext_shell
        super
        @prompt_proc = proc { @sv_stat.to_s + optlist(@int.valid_keys) }
        self
      end

      private

      def ___init_cmd
        rem = @cobj.add_rem
        rem.cfg[:def_msg] = 'ACCEPT'
        rem.add_sys
        @int = rem.add_int
        @cfg[:valid_keys] = @int.valid_keys.clear
        @cobj.get('nonstop').def_proc { @sv_stat.up(:nonstop) }
        @cobj.get('interactive').def_proc { @sv_stat.dw(:nonstop) }
      end

      def ___init_seq(submcr_proc)
        @seq = Sequencer.new(@cfg, &submcr_proc)
        @int.def_proc { |ent| @seq.reply(ent.id) }
        @sv_stat.push(:list, @seq.id).repl(:sid, @seq.id)
        @stat = @seq.record
        @thread = Msg.type?(@seq.fork, Threadx::Fork)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', options: 'eldnr') do |cfg, args|
        mobj = Index.new(cfg)
        mobj.add_rem.add_ext.dev_list
        ent = mobj.set_cmd(args)
        Exe.new(ent).ext_shell.shell
      end
    end
  end
end
