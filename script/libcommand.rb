#!/usr/bin/ruby
require 'libconf'
require 'libgroup'

# @cfg[:def_proc] should be Proc which is given |Entity| as param,
#   returns String as message.
module CIAX
  # Inherited by Index,Domain
  class GrpAry < Arrayx
    include CmdProc
    def initialize(cfg, attr = {})
      @cls_color = 13
      # @cfg is isolated from cfg
      # So it is same meaning to set value to 'attr' and @cfg
      @cfg = cfg.gen(self).update(attr)
    end

    def valid_keys
      map(&:valid_keys).compact.flatten
    end

    def set_cmd(args = [], opt = {})
      id, *par = type?(args, Array)
      valid_keys.include?(id) || fail(InvalidCMD, view_list)
      get(id).set_par(par, opt)
    end

    def valid_pars
      map(&:valid_pars).compact.flatten
    end

    def view_list
      map(&:view_list).compact.grep(/./).join("\n")
    end

    # Add sub group
    # If cls is String or Symbol, constant is taken locally.
    def add(cls, attr = {})
      case cls
      when Module
        res = cls.new(@cfg, attr)
      when String, Symbol
        res = layer_module.const_get(cls).new(@cfg, attr)
      when CmdProc
        res = cls
      else
        sv_err('Not class')
      end
      push res
      res
    end

    def append(obj)
      type?(obj, CmdProc)
      obj.cfg.join_in(@cfg)
      unshift obj
      obj
    end
  end
end
