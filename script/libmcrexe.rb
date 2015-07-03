#!/usr/bin/ruby
require "libmcrseq"
require "libsh"

module CIAX
  module Mcr
    class Exe < Exe
      #required cfg keys: app,db,body,stat
      #cfg[:submcr_proc] for executing asynchronous submacro
      #ent_cfg should have [:db]
      def initialize(cfg)
        @seq=Seq.new(cfg)
        rec=@seq.record
        super(rec.cfg['sid'],rec.cfg)
        @output=rec
        update({'cid'=>@cfg[:cid],'step'=>0,'total_steps'=>@cfg[:body].size,'stat'=>'run','option'=>[]})
        @cobj=Index.new(@cfg)
        @cobj.rem.hid['interrupt'].proc{|ent,src|
          @th_mcr.raise(Interrupt)
          'INTERRUPT'
        }
        ext_shell
      end

      def ext_shell
        int=@cobj.rem.add_int
        warn @cobj.view_list
        int.proc{|ent| reply(ent.id)}
        @seq['option']=int.valid_keys.clear
        super(@cfg[:cid].tr(':','_'))
        @prompt_proc=proc{
          res="(#{@seq['stat']})"
          res+=optlist(@seq['option']) if key?('option')
          res
        }
        vg=@cobj.loc.add_view
        vg['vis'].proc{@output.vmode='v';''}
        vg['raw'].proc{@output.vmode='r';''}
        @cobj.rem.hid[nil].proc{""}
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

      #Takes ThreadGroup to be added
      def fork(tg=nil)
        @th_mcr=Threadx.new("Macro(#@id)",10){@seq.macro}
        tg.add(@th_mcr) if tg.is_a?(ThreadGroup)
        self
      end
    end

    if __FILE__ == $0
      GetOpts.new('cemintr')
      proj=ENV['PROJ']||'ciax'
      cfg=Config.new
      cfg[:jump_groups]=[]
      al=Wat::List.new(cfg).cfg[:sub_list] #Take App List
      cfg[:sub_list]=al
      cfg[:dbi]=Db.new.get(proj)
      begin
        cobj=Index.new(cfg)
        ent=cobj.set_cmd(ARGV)
        mcr=Exe.new(ent.cfg)
        mcr.fork.shell
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
