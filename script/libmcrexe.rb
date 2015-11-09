#!/usr/bin/ruby
require 'libmcrseq'

module CIAX
  module Mcr
    class Exe < CIAX::Exe
      # required cfg keys: app,db,body,stat,(:submcr_proc)
      attr_reader :th_mcr, :seq
      # cfg[:submcr_proc] for executing asynchronous submacro,
      #   which must returns hash with ['id']
      # ent should have [:sequence]'[:dev_list],[:submcr_proc]
      def initialize(ment, pid = '0')
        super(type?(ment, Entity).id)
         # For Thread mode
        @cobj.add_rem.add_hid
        int = @cobj.rem.add_int(Int)
        @seq=Seq.new(ment, pid, int.valid_keys.clear)
        int.def_proc { |ent| @seq.qry.reply(ent.id) }
      end

      def fork
        @th_mcr = Threadx.new("Macro(#{@id})", 10) { @seq.macro }
        @cobj.get('interrupt').def_proc do
          @th_mcr.raise(Interrupt)
          'INTERRUPT'
        end
        self
      end

      def ext_shell
        super
        @prompt_proc = proc { @seq.qry.to_v }
        @cfg[:output] = @seq.record
        @cobj.loc.add_view
        self
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('icemntr')
      cfg = Config.new
      al = Wat::List.new(cfg).sub_list # Take App List
      cfg[:dev_list] = al
      begin
        mobj = Remote::Index.new(cfg, dbi: Db.new.get(PROJ))
        mobj.add_rem.add_ext(Ext)
        ent = mobj.set_cmd(ARGV)
        seq = Exe.new(ent)
        seq.fork.ext_shell.shell
      rescue InvalidCMD
        OPT.usage('[cmd] (par)')
      rescue InvalidID
        OPT.usage('[proj] [cmd] (par)')
      end
    end
  end
end
