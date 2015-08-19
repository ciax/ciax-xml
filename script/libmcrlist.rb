#!/usr/bin/ruby
require "libmcrexe"
module CIAX
  module Mcr
    # Sequencer Layer List
    # @cfg[:db] associated site/layer should be set
    # @cfg should have [:jump_groups]
    class List < CIAX::List
      def initialize(proj,cfg,attr={})
        super(cfg,attr)
        self['id']=proj
        verbose("Initialize [#{proj}]")
      end

      # pid is Parent ID (user=0,mcr_id,etc.) which is source of command issued
      def add(ent,pid='0')
        seq=Seq.new(ent.cfg,{'pid'=>pid})
        put(seq['id'],seq)
      end

      def to_v
        idx=1
        page=['<<< '+Msg.color("Active Macros [#{self['id']}]",2)+' >>>']
        @data.each{|id,seq|
          title="[#{idx}] (#{id})(by #{get_cid(seq['pid'])})"
          msg="#{seq['cid']} [#{seq['step']}/#{seq['total_steps']}]"
          msg << "(#{seq['stat']})#{seq.record.cmd_opt}"
          page << Msg.item(title,msg)
          idx+=1
        }
        page.join("\n")
      end

      def ext_shell
        extend(Shell).ext_shell
      end

      private
      # Getting command ID (ex. run:1)
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
          self
        end

        def get_exe(num)
          n=num.to_i-1
          par_err("Invalid ID") if n < 0 or n > @data.size
          Exe.new(@data[keys[n]]).ext_shell
        end

        def add(ent,pid='0')
          seq=super
          num=size.to_s
          @jumpgrp.add_item(num,seq['cid'])
        end

        def shell
          num=size.to_s
          begin
            get_exe(num).shell
          rescue Jump
            num=$!.to_s
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
      int_cfg=Config.new
      int_cfg[:jump_groups]=[]
      list=SeqList.new(proj,int_cfg).ext_shell

      ext_cfg=Config.new
      ext_cfg[:sub_list]=Wat::List.new(int_cfg).cfg[:sub_list] #Take App List
      mobj=Index.new(ext_cfg)
      mobj.add_rem.add_ext(Db.new.get(proj))

      int_cfg[:submcr_proc]=proc{|args,pid|
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
