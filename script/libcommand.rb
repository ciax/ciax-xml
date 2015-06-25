#!/usr/bin/ruby
require 'libenumx'
require 'libconf'
require 'libgroup'

# @cfg[:def_proc] should be Proc which is given |Entity| as param, returns String as message.
module CIAX
  module Command
    class GrpAry < Arrayx
      attr_reader :cfg
      def initialize(cfg,attr={})
        # Add exe_cfg to @generation as ancestor, add attr to self
        # @cfg is isolated from exe_cfg
        # So it is same meaning to set value to 'attr' and @cfg
        @cfg=cfg.gen(self).update(attr)
        @cfg[:def_proc]||=proc{''}
        @cls_color=@cfg[:cls_color]||7
        @pfx_color=@cfg[:pfx_color]||2
      end

      def get_item(id)
        res=nil
        any?{|e| res=e.get_item(id)}
        res
      end

      def item_proc(id,&def_proc)
        get_item(id).cfg.proc(&def_proc)
      end

      def valid_keys
        map{|e| e.valid_keys}.flatten
      end

      def set_cmd(args,opt={})
        id,*par=type?(args,Array)
        valid_keys.include?(id) || raise(InvalidCMD,view_list)
        get_item(id).set_par(par,opt)
      end

      def valid_pars
        map{|e| e.valid_pars}.flatten
      end

      def view_list
        map{|e| e.view_list}.grep(/./).join("\n")
      end

      def show_proc(id)
        item=get_item(id)
        cfg=item.cfg
        cls=cfg.generation[cfg.level(:def_proc)][:level]
        " #{id},level=#{cls},item=#{item.object_id},proc=#{cfg[:def_proc].object_id}"
      end

      def add(cls,attr={})
        unshift obj=cls.new(@cfg,attr)
        obj
      end

      def put(obj) # Destroy obj.cfg
        obj.cfg.join_in(@cfg)
        unshift obj
        self
      end
    end
  end
end
