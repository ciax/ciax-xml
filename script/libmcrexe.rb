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
        super(@seq['cid'],@seq.cfg)
        seq_cfg=Config.new
        seq_cfg[:jump_groups]=@seq.cfg[:jump_groups]
        @cfg[:output]=@seq.record
        @cobj=Index.new(seq_cfg)
        @cobj.add_rem.add_hid
        @cobj.get('interrupt').def_proc{|ent,src|
          @th_mcr.raise(Interrupt)
          'INTERRUPT'
        }
        @cobj.rem.add_int(@seq['option']).valid_clear
        @cobj.rem.int.add_item('start','Sequece Start').def_proc{|ent|
          @seq.start(true)
          'ACCEPT'
        }
      end

      def ext_shell
        extend(Shell).ext_shell
      end

      module Shell
        include CIAX::Shell
        def ext_shell
          super
          @prompt_proc=proc{
            res="(#{@seq['stat']})"
            res+=optlist(@seq['option'])
            res
          }
          @cobj.rem.int.def_proc{|ent|
            @seq.reply(ent.id)
          }
          @cobj.loc.add_view(:output => @cfg[:output])
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
