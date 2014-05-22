#!/usr/bin/ruby
require "libmcrexe"

module CIAX
  module Mcr
    class List < Datax
      attr_accessor :sid
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
        @sid=sid||@sid||return
        begin
          @data[@sid].shell
        rescue SiteJump
          @sid=$!.to_s
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
          msg << "#{mst.optlist}?" unless mst['option'].empty?
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

      def add(ent)
        ssh=Seq.new(type?(ent,Entity))
        @sid=ssh.id
        @data[@sid]=ssh
        @mjgrp.add_item(@sid,ent.id)
        ssh.cobj.lodom.join_group(@mjgrp)
        ssh.post_stat_procs << proc{upd}
        ssh.post_mcr_procs << proc{|s| clean(s.id)}
        ssh.fork(@tgrp)
        self
      end

      def clean(sid)
        @data.delete(sid)
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
        set_proc{|ent| raise(SiteJump,ent.id)}
      end
    end

    if __FILE__ == $0
      ENV['VER']||='init/'
      GetOpts.new('t')
      begin
        cfg=Config.new('mcr_list')
        cfg[:app_list]=App::List.new
        cfg[:db]=Db.new.set('ciax')
        cobj=Command.new(cfg).add_ext
        list=SvList.new('ciax')
        ARGV.each{|cid|
          ent=cobj.set_cmd(cid.split(':'))
          list.add(ent)
        }
        list.shell||cobj.set_cmd([])
      rescue InvalidCMD
        $opt.usage('[cmd(:par)] ...')
      end
    end
  end
end
