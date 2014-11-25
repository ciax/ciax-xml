#!/usr/bin/ruby
require "libdatax"

module CIAX
  module JumpList
    class List < Datax
      def initialize(level,upper=nil)
        @level=type?(level,Module)
        name=level.to_s.split(':').last
        @cfg=Config.new("#{name.downcase}_list",upper)
        super(name,{},@cfg[:dataname]||'list')
        attr={'caption'=>"Switch #{name}s",'color'=>5,'column'=>2}
        @jumpgrp=Group.new(@cfg,attr).set_proc{|ent|
          raise(@level::Jump,ent.id)
        }
        jg=@cfg[:jump_groups]=(@cfg[:jump_groups]||[]).dup
        jg << @jumpgrp
        $opt||=GetOpts.new
      end

      def shell(key=nil,par=nil)
        begin
          (get(key)||lastval).shell(par)
        rescue @level::Jump
          key,par=$!.to_s.split(':')
          retry
        rescue InvalidID
          $opt.usage('(opt) [id]')
        end
      end

      private
      # For generate Exe (allows nil)
      def add(key)
      end

      def jumpgrp(lower)
        @cfg[:jump_groups].each{|grp|
          lower.cobj.lodom.join_group(grp)
        }
        lower
      end
    end
  end
end
