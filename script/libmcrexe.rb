#!/usr/bin/ruby
require "libmcrseq"
require "libsh"

module CIAX
  module Mcr
    # Sequencer Layer Shell
    class Exe < Exe
      #required cfg keys: app,db,body,stat
      #cfg[:submcr_proc] for executing asynchronous submacro
      #ent_cfg should have [:dbi]
      def initialize(seq)
        @seq=type?(seq,Seq)
        super(seq['cid'],seq.cfg)
        cfg=Config.new
        cfg[:jump_groups]=seq.cfg[:jump_groups]
        @cobj=Index.new(cfg)
        @cobj.add_rem.add_hid
        @cobj.get('interrupt').def_proc{|ent,src|
          @th_mcr.raise(Interrupt)
          'INTERRUPT'
        }
        @cobj.rem.add_int(@seq['option'])
        @cobj.get('start').def_proc{|ent|
          @seq.fork
          'ACCEPT'
        }
      end

      def ext_shell
        extend(Shell).ext_shell
      end

      module Shell
        include CIAX::Shell
        def ext_shell
          super(@cfg[:cid].tr(':','_'))
          @output=@seq.record
          @prompt_proc=proc{
            res="(#{@seq['stat']})"
            res+=optlist(@seq['option'])
            res
          }
          @cobj.rem.int.def_proc{|ent|
            @seq.reply(ent.id)
          }
          vg=@cobj.loc.add_view
          vg.get('vis').def_proc{@output.vmode='v';''}
          vg.get('raw').def_proc{@output.vmode='r';''}
          self
        end
      end
    end

    if __FILE__ == $0
      GetOpts.new('cemintr')
      proj=ENV['PROJ']||'ciax'
      cfg=Config.new
      cfg[:jump_groups]=[]
      al=Wat::List.new(cfg).cfg[:sub_list] #Take App List
      cfg[:sub_list]=al
      mobj=Index.new(cfg)
      mobj.add_rem
      mobj.rem.add_ext(Db.new.get(proj))
      begin
        ent=mobj.set_cmd(ARGV)
        seq=Seq.new(ent.cfg)
        mcr=Exe.new(seq).ext_shell
        mcr.shell
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
