#!/usr/bin/ruby
require 'libconf'
require 'libgroup'

# @cfg[:def_proc] should be Proc which is given |Entity| as param, returns String as message.
module CIAX
  module Command
    class GrpAry < Arrayx
      include CmdProc
      def initialize(cfg,attr={})
        @cls_color=13
        # @cfg is isolated from cfg
        # So it is same meaning to set value to 'attr' and @cfg
        @cfg=cfg.gen(self).update(attr)
      end

      def valid_keys
        map{|e| e.valid_keys}.flatten
      end

      def set_cmd(args=[],opt={})
        id,*par=type?(args,Array)
        valid_keys.include?(id) || raise(InvalidCMD,view_list)
        get(id).set_par(par,opt)
      end

      def valid_pars
        map{|e| e.valid_pars}.flatten
      end

      def view_list
        map{|e| e.view_list}.grep(/./).join("\n")
      end

      # If cls is String or Symbol, constant is taken locally.
      def add(obj,attr={})
        case obj
        when Module
          res=obj.new(@cfg,attr)
        when String,Symbol
          res=layer_module.const_get(obj).new(@cfg,attr)
        when CmdProc
          obj.cfg.join_in(@cfg)
          res=obj
        else
          sv_err("Not class or element")
        end
        unshift res
        res
      end
    end
  end
end
