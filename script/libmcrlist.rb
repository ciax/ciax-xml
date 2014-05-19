#!/usr/bin/ruby
require "libmcrexe"

module CIAX
  module Mcr
    class List < Datax
      attr_accessor :current
      def initialize(proj,ver=0)
        super('macro',{},'procs')
        self['id']=proj
        self['ver']=ver
      end

      def get_obj(sid)
        @data[sid]
      end

      def sid_to_num(num) #convert the order number(Integer) to sid
        @data.keys[num-1]
      end

      def shell(sid)
        @sid=sid||@sid
        begin
          @data[@sid].shell
        rescue SiteJump
          @sid=$!.to_s
          retry
        end
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
      end

      def add(sobj)
        sid=type?(sobj,Seq).id
        @data[sid]=sobj
        sobj.post_stat_procs << proc{upd}
        sobj.post_exe_procs << proc{|s|
          clean(s.id)
          upd
        }
        @tgrp.add(sobj.fork)
        self
      end

      def clean(sid)
        @data.delete(sid)
        @data.keys.each{|id|
          @tgrp.list.any?{|t|
            id == t[:sid]
          }||@data.delete(id)
        }
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
        update_items(@cfg[:ldb].list)
        set_proc{|ent| raise(SiteJump,ent.id)}
      end
    end

    if __FILE__ == $0
      ENV['VER']||='init/'
      GetOpts.new('t')
      begin
        cfg=Config.new
        cfg[:app_list]=App::List.new
        cfg[:db]=Db.new.set('ciax')
        ent=Command.new(cfg).add_ext.set_cmd(ARGV)
        seq=Seq.new(ent).ext_shell
        seq.fork
        SvList.new('ciax').add(seq).shell(seq.id)
      rescue InvalidCMD
        $opt.usage('[cmd] (par)')
      end
    end
  end
end
