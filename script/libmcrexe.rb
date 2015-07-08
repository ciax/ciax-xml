#!/usr/bin/ruby
require "libmcrseq"
require "libsh"

module CIAX
  module Mcr
    class Exe < Exe
      #required cfg keys: app,db,body,stat
      #cfg[:submcr_proc] for executing asynchronous submacro
      #ent_cfg should have [:db]
      def initialize(seq)
        @seq=type?(seq,Seq)
        rec=@seq.record
        super(rec['id'],rec.cfg)
        cfg=Config.new
        cfg[:jump_groups]=rec.cfg[:jump_groups]
        @cobj=Index.new(cfg)
        @cobj.add_rem.add_hid
        @cobj.get_item('interrupt').proc{|ent,src|
          @th_mcr.raise(Interrupt)
          'INTERRUPT'
        }
        @cobj.rem.add_int(@seq['option']).proc{|ent|
          reply(ent.id)
        }
      end

      def ext_shell
        super(@cfg[:cid].tr(':','_'))
        @output=@seq.record
        @prompt_proc=proc{
          res="(#{@seq['stat']})"
          res+=optlist(@seq['option'])
          res
        }
        vg=@cobj.loc.add_view
        vg['vis'].proc{@output.vmode='v';''}
        vg['raw'].proc{@output.vmode='r';''}
        self
      end

      def reply(ans)
        if @seq['stat'] == 'query'
          @seq.que_cmd << ans
          @seq.que_res.pop
        else
          "IGNORE"
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
        seq=Seq.new(ent.cfg).fork
        mcr=Exe.new(seq).ext_shell
        mcr.shell
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
