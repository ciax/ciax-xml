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
          atrb[:caption] = 'System Commands'
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
          atrb[:caption] = 'Internal Commands'
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

    # For External Command Domain
    # @cfg must contain [:dbi]
    # Content of Dbi[:command][:index][id] will be merged in Item@cfg
    module Ext
      # External Command Group
      class Group < Group
        def initialize(cfg, atrb = {})
          atrb[:caption] = 'External Commands'
          super
          dbi = type?(@cfg[:dbi], Dbi)
          @cfg[:ver] ||= dbi[:version]
          # Set items by DB
          cdb = dbi[:command]
          idx = cdb[:index]
          @dispgrp = @displist.set_sec
          cdb[:group].each do|gid, gat|
            c = 0 if /true|1/ =~ gat[:hidden]
            sg = @dispgrp.put_grp(gid, gat[:caption], c)
            gat[:members].each do|id|
              sg.put_item(id, idx[id][:label])
              add_item(id, cdb, idx[id])
            end
          end
          init_alias(cdb, idx)
          @displist.reset!
        end

        def init_alias(cdb, idx)
          return unless cdb[:alias]
          sg = @dispgrp.put_grp('gal', 'Alias')
          cdb[:alias].each do|id, att|
            item = idx[att[:ref]].dup
            item.update(att)
            sg.put_item(id, att[:label])
            add_item(id, cdb, item)
          end
        end

        def add_item(id, cdb, item)
          label = item[:label]
          unit = item[:unit]
          label = "#{cdb[:unit][unit][:label]} #{label}" if unit
          if item[:parameters].is_a? Array
            label.gsub(/\$([\d]+)/, '%s') % item[:parameters].map { |e| e[:label] }
          end
          new_item(id, item)
        end
      end

      class Item < Item; end

      # Substitute string($+number) with parameters
      # par={ val,range,format } or String
      # str could include Math functions
      class Entity < Entity
        def initialize(grp_cfg, atrb = {})
          super
          type?(self[:dbi], Dbi)
          @body = deep_subst(self[:body])
        end

        def subst(str) # subst by parameters ($1,$2...)
          return str unless /\$([\d]+)/ =~ str
          enclose("Substitute from [#{str}]", 'Substitute to [%s]') do
            num = true
            res = str.gsub(/\$([\d]+)/) do
              i = Regexp.last_match(1).to_i
              num = false if self[:parameters][i - 1][:type] != 'num'
              verbose { "Parameter No.#{i} = [#{@par[i - 1]}]" }
              @par[i - 1] || Msg.cfg_err(" No substitute data ($#{i})")
            end
            Msg.cfg_err('Nil string') if res == ''
            res
          end
        end

        def deep_subst(data)
          case data
          when Array
            res = []
            data.each do|v|
              res << deep_subst(v)
            end
          when Hash
            res = {}
            data.each do|k, v|
              res[k] = deep_subst(v)
            end
          else
            res = subst(data)
          end
          res
        end
      end
    end
  end
end
