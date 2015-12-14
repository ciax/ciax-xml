#!/usr/bin/ruby
require 'liblocal'
require 'libparam'
module CIAX
  # Remote Command Domain
  module Remote
    NS_COLOR = 1
    # Instance var is @rem in Index
    class Index < Local::Index
      attr_reader :rem
      def add_rem(obj = 'Domain')
        @rem = add(obj)
      end
    end

    # @cfg should have [:dbi]
    class Domain < GrpAry
      attr_reader :sys, :ext, :int
      def initialize(cfg, atrb = {})
        super
        @cfg[:def_proc] = proc { '' } # proc is re-defined
      end

      def add_sys(ns = Sys)
        @sys = add(ns::Group)
      end

      def add_ext(ns = Ext)
        type?(@cfg[:dbi], Dbi)
        @ext = add(ns::Group)
      end

      def add_int(ns = Int)
        @int = add(ns::Group)
      end
    end

    module Sys
      # System Command Group
      class Group < Group
        def initialize(dom_cfg, atrb = {})
          atrb[:caption] ||= 'System Commands'
          super
          add_item('interrupt')
          # Accept empty command
          add_item(nil) unless @cfg[:exe_mode]
        end
      end
    end

    module Int
      # Internal Command Group
      class Group < Group
        def initialize(dom_cfg, atrb = {})
          atrb[:caption] ||= 'Internal Commands'
          super
          @cfg[:nocache] = true
        end

        def def_pars(n = 1)
          ary = []
          n.times { ary << Parameter.new }
          { parameters: ary }
        end
      end
      class Item < Item; end
      class Entity < Entity; end
    end
  end
end
