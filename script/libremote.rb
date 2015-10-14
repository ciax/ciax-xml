#!/usr/bin/ruby
require 'liblocal'

module CIAX
  module Remote
    # Instance var is @rem in Index
    class Index < Local::Index
      attr_reader :rem
      def add_rem(obj = 'Domain')
        @rem = add(obj)
      end
    end

    # @cfg should have [:dbi]
    class Domain < GrpAry
      attr_reader :hid, :ext, :int
      def initialize(cfg, attr = {})
        super
        @cfg[:def_proc] = proc { '' } # proc is re-defined
      end

      def add_hid(ns = Hid)
        @hid = add(ns::Group)
      end

      def add_ext(ns = Ext)
        type?(@cfg[:dbi], Dbi)
        @ext = add(ns::Group)
      end

      def add_int(ns = Int)
        @int = add(ns::Group)
      end
    end

    module Hid
      class Group < Group
        def initialize(dom_cfg, attr = {})
          super
          @cfg['caption'] = 'Hidden Commands'
          add_item('interrupt')
          # Accept empty command
          add_item(nil) unless @cfg[:exe_mode]
        end
      end
    end

    module Int
      class Group < Group
        def initialize(dom_cfg, attr = {})
          super
          @cfg['caption'] = 'Internal Commands'
        end

        def def_pars(n = 1)
          any = { type: 'reg', list: ['.'] }
          ary = []
          n.times { ary << any }
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
      class Group < Group
        def initialize(cfg, attr = {})
          super
          dbi = type?(@cfg[:dbi], Dbi)
          @cfg['caption'] ||= 'External Commands'
          @cfg['ver'] ||= dbi['version']
          # Set items by DB
          cdb = dbi[:command]
          idx = cdb[:index]
          cdb[:group].values.each do|gat|
            @subgrp = @displist.new_grp(gat['caption'])
            gat[:members].each do|id|
              item = idx[id]
              add_item(id, cdb, item)
            end
          end
          init_alias(cdb, idx)
        end

        def init_alias(cdb, idx)
          return unless cdb[:alias]
          @subgrp = @displist.new_grp('Alias')
          cdb[:alias].each do|id, att|
            item = idx[att['ref']].dup
            item.update(att)
            add_item(id, cdb, item)
          end
        end

        def add_item(id, cdb, item)
          label = item['label']
          unit = item['unit']
          label = "#{cdb[:unit][unit]['label']} #{label}" if unit
          if item[:parameters].is_a? Array
            label = label.gsub(/\$([\d]+)/, '%s') % item[:parameters].map { |e| e['label'] }
          end
          @subgrp[id] = label
          new_item(id, item)
        end
      end

      class Item < Item; end

      class Entity < Entity
        # Substitute string($+number) with parameters
        # par={ val,range,format } or String
        # str could include Math functions
        def initialize(grp_cfg, attr = {})
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
