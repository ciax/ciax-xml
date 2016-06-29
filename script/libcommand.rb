#!/usr/bin/ruby
require 'libcmdgroup'

# @cfg[:def_proc] should be Proc which is given |Entity| as param,
#   returns String as message.
module CIAX
  module Cmd
    # Inherited by Index,Domain
    class GrpAry < Arrayx
      include CmdProc
      def initialize(cfg, atrb = Hashx.new)
        # @cfg is isolated from cfg
        # So it is same meaning to set value to 'atrb' and @cfg
        @cfg = cfg.gen(self).update(type?(atrb, Hash))
      end

      def valid_keys
        map(&:valid_keys).compact.flatten
      end

      def set_cmd(args = [], opt = {})
        id, *par = type?(args, Array)
        valid_keys.include?(id) || cmd_err
        get(id).set_par(par, opt)
      end

      def valid_pars
        map(&:valid_pars).compact.flatten
      end

      def view_list
        map(&:view_list).compact.grep(/./).join("\n")
      end

      def cmd_err
        raise(InvalidCMD, view_list)
      end

      # Add sub group
      # If cls is String or Symbol, constant is taken locally.
      def add(cls, atrb = Hashx.new)
        res = _get_cls(cls, atrb)
        push res
        res
      end

      def append(obj)
        type?(obj, CmdProc)
        obj.cfg.join_in(@cfg)
        unshift obj
        obj
      end

      private

      def _get_cls(cls, atrb)
        case cls
        when Module
          cls.new(@cfg, atrb)
        when String, Symbol
          layer_module.const_get(cls).new(@cfg, atrb)
        when CmdProc
          cls
        else
          sv_err('Not class')
        end
      end
    end
  end
end
