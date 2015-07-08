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
        @cls_color=13
        # @cfg is isolated from cfg
        # So it is same meaning to set value to 'attr' and @cfg
        @cfg=cfg.gen(self).update(attr)
      end

      def get_item(id)
        res=nil
        any?{|e| res=e.get_item(id)}
        res
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

      # Proc should return String
      def proc(&def_proc)
        @cfg[:def_proc]=type?(def_proc,Proc)
        self
      end

      # If cls is String or Symbol, constant is taken locally.
      def add(cls,attr={})
        case cls
        when Module
          mod=cls
        when String,Symbol
          mod=layer_module.const_get(cls)
        else
          sv_err("Not class")
        end
        unshift obj=mod.new(@cfg,attr)
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
