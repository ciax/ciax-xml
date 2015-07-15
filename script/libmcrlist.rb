#!/usr/bin/ruby
require "libmcrexe"
module CIAX
  module Mcr
    # Sequencer Layer List
    # @cfg[:db] associated site/layer should be set
    # @cfg should have [:jump_group],[:layer_list]
    class List < CIAX::List
      attr_accessor :index
      def initialize(id,cfg,attr={})
        super(cfg,attr)
        self['id']=id
        verbose("Initialize [#{id}]")
        @stack=[]
        @index=[] # Will be :valid_pars in Man
      end

      def get(id)
        upd
        super
      end

      def add(ent,pid='0')
        seq=Seq.new(ent.cfg)
        seq.pre_mcr_procs << proc{|id,seq|
          put(id,seq)
          @index << id
        }
        seq['pid']=pid
        @stack.push seq
        seq.post_stat_procs << proc{upd}
        seq
      end

      def ext_shell
        extend(Shell).ext_shell
      end

      def to_v
        idx=1
        page=['<<< '+Msg.color("Active Macros [#{self['id']}]",2)+' >>>']
        @data.each{|id,seq|
          title="[#{idx}] (#{id})(by #{get_cid(seq['pid'])})"
          opt=Msg.color('['+seq['option'].join('/')+']',5) unless seq['option'].empty?
          msg="#{seq['cid']} [#{seq['step']}/#{seq['total_steps']}](#{seq['stat']})#{opt}"
          page << Msg.item(title,msg)
          idx+=1
        }
        page.join("\n")
      end

      private
      def get_cid(id)
        return 'user' if id == '0'
        get(id)['cid']
      end

      module Shell
        include CIAX::List::Shell
        class Jump < LongJump; end

        def ext_shell
          super(Jump)
          @cfg[:sub_list].ext_shell if @cfg.key?(:sub_list) # Limit self level
          @exelist={}
          self
        end

        def get_exe(id)
          n=id.to_i-1
          par_err("Invalid ID") if n < 0
          @exelist[id]||=Exe.new(@stack[n]).ext_shell
        end

        def add(ent,parent='user')
          seq=super
          id=@stack.size.to_s
          @index << id
          @jumpgrp.add_item(id,seq['cid'])
          seq
        end

        def shell
          id=@stack.size.to_s
          begin
            get_exe(id).shell
          rescue Jump
            id=$!.to_s
            retry
          rescue InvalidID
            $opt.usage('(opt) [site]')
          end
        end
      end
    end
      
    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('tenr')
      proj=ENV['PROJ']||'ciax'
      cfg=Config.new
      cfg[:jump_groups]=[]
      cfg[:sub_list]=Wat::List.new(cfg).cfg[:sub_list] #Take App List
      list=List.new(proj,cfg).ext_save.ext_shell
      mobj=Index.new(list.cfg)
      mobj.add_rem.add_ext(Db.new.get(proj))
      cfg[:submcr_proc]=proc{|args,pid|
        ent=mobj.set_cmd(args)
        list.add(ent,pid)
      }
      begin
        mobj.set_cmd if ARGV.empty?
        ARGV.each{|cid|
          ent=mobj.set_cmd(cid.split(':'))
          list.add(ent)
        }
        list.shell
      rescue InvalidCMD
        $opt.usage('[cmd(:par)] ...')
      end
    end
  end
end
