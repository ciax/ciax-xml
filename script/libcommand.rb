#!/usr/bin/ruby
require 'libcmdgroup'

# @cfg[:def_proc] should be Proc which is given |Entity| as param,
#   returns String as message.
module CIAX
  module CmdBase
    # Inherited by Index,Domain
    class GrpAry < Arrayx
      include CmdProc
      def initialize(cfg, atrb = Hashx.new)
        # @cfg is isolated from cfg
        # So it is same meaning to set value to 'atrb' and @cfg
        @cfg = cfg.gen(self).update(type?(atrb, Hash))
        @layer = @cfg[:layer]
      end

      def valid_keys
        # map{ |e| e.valid_keys }
        map(&:valid_keys).compact.flatten
      end

      def valid_pars
        map(&:valid_pars).compact.flatten
      end

      def view_list
        map(&:view_list).compact.grep(/./).join("\n")
      end

      # Add sub group
      # If cls is String or Symbol, constant is taken locally.
      def add(cls, atrb = Hashx.new) # returns instance of cls
        res = ___get_cls(cls, atrb)
        push res
        res
      end

      def append(obj) # return obj
        type?(obj, CmdProc)
        obj.cfg.join_in(@cfg)
        unshift obj
        obj
      end

      private

      def ___get_cls(cls, atrb)
        case cls
        when Module
          cls.new(@cfg, atrb)
        when String, Symbol
          context_module(cls).new(@cfg, atrb)
        when CmdProc
          cls
        else
          sv_err('Not class')
        end
      end
    end

    # Top Level Command Index
    class Index < GrpAry
      def initialize(cfg, atrb = Hashx.new)
        atrb[:index] = self
        super
      end

      def add_dom(ns, atrb = Hashx.new)
        add("#{ns}::Domain", atrb)
      end

      def set_cmd(args = [], opt = {})
        id, *par = type?(args, Array)
        valid_keys.include?(id) || cmd_err(view_list)
        get(id).set_par(par, opt)
      end
    end

    # Commmand Domain (Remote or Local)
    class Domain < GrpAry
      def add_grp(ns, atrb = Hashx.new)
        add("#{ns}::Group", atrb)
      end
    end
  end
end
