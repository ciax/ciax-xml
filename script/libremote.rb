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

    # For External Command Domain
    # @cfg must contain [:dbi]
    # Content of Dbi[:command][:index][id] will be merged in Item@cfg
    module Ext
      # External Command Group
      class Group < Group
        def initialize(cfg, atrb = {})
          atrb[:caption] ||= 'External Commands'
          super
          dbi = type?(@cfg[:dbi], Dbi)
          @cfg[:ver] ||= dbi[:version]
          @displist = @displist.ext_grp
          _init_items(dbi[:command])
          @displist.reset!
        end

        def add_item(id, cdb, itm)
          label = itm[:label]
          unit = itm[:unit]
          label = "#{cdb[:unit][unit][:label]} #{label}" if unit
          if itm[:parameters].is_a? Array
            label.gsub(/\$([\d]+)/, '%s') % itm[:parameters].map { |e| e[:label] }
          end
          new_item(id, itm)
        end

        private

        # Set items by DB
        def _init_items(cdb)
          cdb[:group].each do|gid, gat|
            sg = @displist.put_grp(gid, gat[:caption], nil, gat[:rank])
            _init_member_(cdb, gat[:members], sg)
            _init_unit_(cdb, gat[:units], sg)
          end
          _init_alias_(cdb)
        end

        def _init_member_(cdb, mem, sg)
          mem.each do|id|
            itm = cdb[:index][id]
            sg.put_item(id, itm[:label])
            add_item(id, cdb, itm)
          end
        end

        def _init_unit_(cdb, guni, sg)
          return unless guni
          guni.each do|u|
            uat = cdb[:unit][u]
            if uat.key?(:title)
              sg.put_dummy(uat[:title], uat[:label])
              sg.replace(sg - uat[:members])
            end
          end
        end

        def _init_alias_(cdb)
          return unless cdb[:alias]
          sg = @displist.put_grp('gal', 'Alias')
          cdb[:alias].each do|id, att|
            itm = cdb[:index][att[:ref]].dup
            sg.put_item(id, att[:label])
            add_item(id, cdb, itm)
          end
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


        def deep_subst(data)
          case data
          when Array
            res = []
            data.each { |v| res << deep_subst(v) }
          when Hash
            res = {}
            data.each { |k, v| res[k] = deep_subst(v) }
          else
            res = _subst_(data)
          end
          res
        end
        private

        def _subst_(str) # subst by parameters ($1,$2...)
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
      end
    end
  end
end
