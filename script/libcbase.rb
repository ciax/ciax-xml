#!/usr/bin/env ruby
require 'libcbasegroup'

# @cfg[:def_proc] should be Proc which is given |Entity| as param,
#   returns String as message.
module CIAX
  # CmdBase includes
  #  Index, Domain, Group, Form, Entity, ParArray, Parameter
  module CmdBase
    # Inherited by Index,Domain
    class GrpAry < Arrayx
      include CmdFunc
      def initialize(spcfg, atrb = Hashx.new)
        # @cfg is isolated from cfg
        # So it is same meaning to set value to 'atrb' and @cfg
        @cfg = spcfg.gen(self).update(type?(atrb, Hash))
        @layer = @cfg[:layer]
      end

      def all_keys
        map(&:all_keys).compact.flatten
      end

      def valid_keys
        # map{ |e| e.valid_keys }
        map(&:valid_keys).compact.flatten
      end

      def valid_pars
        map(&:valid_pars).compact.flatten
      end

      def view_dic
        map(&:view_dic).compact.grep(/./).join("\n")
      end

      # Add sub group
      # If cls is String or Symbol, constant is taken locally.
      def add(cls, atrb = Hashx.new) # returns instance of cls
        res = ___get_cls(cls, atrb)
        push res
        res
      end

      def append(obj) # return obj
        type?(obj, CmdFunc)
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
        when CmdFunc
          cls
        else
          sv_err('Not class')
        end
      end
    end

    # Top Level Command Index
    #  This instance will be assigned as @cobj in other classes
    class Index < GrpAry
      def initialize(spcfg, atrb = Hashx.new)
        atrb[:index] = self
        super
      end

      def add_dom(ns, atrb = Hashx.new)
        add("#{ns}::Domain", atrb)
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
