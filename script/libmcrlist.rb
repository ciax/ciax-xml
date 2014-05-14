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
        sobj.post_stat_procs << proc{save}
        sobj.post_exe_procs << proc{|s|
          clean(s.id)
          save
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
  end
end
