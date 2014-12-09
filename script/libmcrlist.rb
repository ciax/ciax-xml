#!/usr/bin/ruby
require "liblist"
require "libmcrexe"

module CIAX
  module Mcr
    class List < List
      attr_reader :jumpgrp
      def initialize(proj,ver=0)
        @cfg=Config.new('mcr_list')
        @cfg[:dataname]='procs'
        @cfg["line_number"]=true
        super(Mcr,@cfg)
        self['id']=proj
        self['ver']=ver
      end

      #convert the order number(Integer) to sid
      def num_to_sid(num)
        @data.keys[num-1]
      end

      def sid_to_num(sid)
        @data.keys.index(sid)
      end

      def to_s
        idx=1
        page=['<<< '+Msg.color('Active Macros',2)+' >>>']
        @data.each{|key,mst|
          title="[#{idx}](#{key})"
          msg="#{mst['cid']} [#{mst['step']}/#{mst['total_steps']}](#{mst['stat']})"
          msg << optlist(mst['option'])
          page << Msg.item(title,msg)
          idx+=1
        }
        page.join("\n")
      end
    end

    class SvList < List
      def initialize(proj,ver=0)
        super
        @tgrp=ThreadGroup.new
        @cfg[:valid_keys]=@valid_keys=[]
        @post_upd_procs << proc{ @valid_keys.replace(@data.keys)}
      end

      def set(id,exe)
        type?(exe,Exe)
        @jumpgrp.add_item(id,exe['cid'])
        # JumpGroup is set to Domain
        @cfg[:jump_groups].each{|grp|
          exe.cobj.lodom.join_group(grp)
        }
        exe.shell_input_proc=proc{|args|
          num=args[0].to_i
          if num > 0 && num < 100
            args[0]=num_to_sid(num)||''
          end
          args
        }
        super
      end

      def add_seq(ent)
        ssh=Seq.new(type?(ent,Entity))
        ssh.post_stat_procs << proc{upd}
        ssh.post_mcr_procs << proc{|s|
          @data.delete(s.id)
          clean
        }
        set(ssh.id,ssh)
        ssh.fork(@tgrp)
        self
      end

      def clean
        @data.keys.each{|id|
          @tgrp.list.any?{|t|
            id == t[:sid]
          }||@data.delete(id)
        }
        upd
      end

      def interrupt
        @tgrp.list.each{|t|
          t.raise(Interrupt)
        }
        self
      end
    end

    class Jump < LongJump; end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('ten')
      begin
        cfg=Config.new('mcr_list')
        cfg[:wat_list]=Wat::List.new
        cfg[:db]=Db.new.set('ciax')
        cobj=Command.new(cfg).add_ext
        list=SvList.new('ciax')
        ARGV.each{|cid|
          ent=cobj.set_cmd(cid.split(':'))
          list.add_seq(ent)
        }.empty? && cobj.set_cmd([])
        list.shell
      rescue InvalidCMD
        $opt.usage('[cmd(:par)] ...')
      end
    end
  end
end
