#!/usr/bin/ruby
require "libmcrexe"

module CIAX
  module Mcr
    class List < Datax
      attr_accessor :current # SID(String)
      def initialize(proj,ver=0)
        super('macro',{},'procs')
        self['id']=proj
        self['ver']=ver
      end

      def get_obj(sid)
        @data[sid]
      end

      #convert the order number(Integer) to sid
      def num_to_sid(num)
        @data.keys[num-1]
      end

      def sid_to_num(sid)
        @data.keys.index(sid)
      end

      def shell(sid=nil)
        @current=sid||@current||return
        begin
          @data[@current].shell
        rescue SiteJump
          @current=$!.to_s
          retry
        end
        self
      rescue InvalidID
        $opt.usage('(opt) [id]')
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
        @cfg=Config.new('mcr_list')
        @cfg[:valid_keys]=@valid_keys=[]
        @mjgrp=JumpGrp.new(@cfg)
        @post_upd_procs << proc{ @valid_keys.replace(@data.keys)}
      end

      def add_seq(ent)
        ssh=Seq.new(type?(ent,Entity))
        @current=ssh.id
        @data[@current]=ssh
        @mjgrp.add_item(@current,ent.id)
        ssh.cobj.lodom.join_group(@mjgrp)
        ssh.post_stat_procs << proc{upd}
        ssh.post_mcr_procs << proc{|s|
          @data.delete(s.id)
          clean
        }
        ssh.shell_input_proc=proc{|line|
          args=line.split(' ')
          num=args[0].to_i
          if num > 0 && num < 100
            args[0]=@data.keys[num-1]||''
          end
          args
        }
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

    class JumpGrp < Group
      def initialize(upper,crnt={})
        super
        @cfg['caption']='Switch Macros'
        @cfg['color']=5
        @cfg['column']=2
        @cfg['line_number']=true
        set_proc{|ent| raise(SiteJump,ent.id)}
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('t')
      begin
        cfg=Config.new('mcr_list')
        cfg[:wat_list]=Wat::List.new
        cfg[:db]=Db.new.set('ciax')
        cobj=Command.new(cfg).add_ext
        list=SvList.new('ciax')
        ARGV.each{|cid|
          ent=cobj.set_cmd(cid.split(':'))
          list.add_seq(ent)
        }
        list.shell||cobj.set_cmd([])
      rescue InvalidCMD
        $opt.usage('[cmd(:par)] ...')
      end
    end
  end
end
