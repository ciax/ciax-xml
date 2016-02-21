#!/usr/bin/ruby
require 'libmcrseq'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Shell interface for Seq
    class Exe < CIAX::Exe
      attr_reader :th_mcr, :seq
      # ment should have [:sequence]'[:dev_list],[:submcr_proc]
      def initialize(ment, pid = '0')
        cfg = Config.new
        super(type?(ment, Cmd::Entity).id, cfg)
        _init_sub
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
        @seq = Seq.new(ment, pid, int.valid_keys.clear)
        int.def_proc { |ent| @seq.reply(ent.id) }
      end

      # For Thread mode
      def _init_thread_
        @th_mcr = @seq.fork
        # interrupt is in rem.hid group
        @cobj.get('interrupt').def_proc do
          @th_mcr.raise(Interrupt)
          'INTERRUPT'
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      opt = GetOpts.new('icentr')
      cfg = Config.new(option: opt)
      cfg[:dev_list] = Wat::List.new(cfg)
      begin
        dbi = Db.new.get
        mobj = Cmd::Remote::Index.new(cfg, dbi.pick([:sites]))
        mobj.add_rem.add_ext(Ext)
        ent = mobj.set_cmd(ARGV)
        seq = Exe.new(ent)
        seq.ext_shell.shell
      rescue InvalidCMD
        opt.usage('[cmd] (par)')
      rescue InvalidID
        opt.usage('[proj] [cmd] (par)')
      end
    end
  end
end
