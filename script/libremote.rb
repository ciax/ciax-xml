#!/usr/bin/ruby
require 'liblocal'

module CIAX
  # Remote Command Domain
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
      def initialize(cfg, atrb = {})
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

    # Hidden Command Group
    module Hid
      class Group < Group
        def initialize(dom_cfg, atrb = {})
          atrb[:caption] = 'Hidden Commands'
          super
          add_item('interrupt')
          # Accept empty command
          add_item(nil) unless @cfg[:exe_mode]
        end
      end
    end

    # Internal Command Group
    module Int
      class Group < Group
        def initialize(dom_cfg, atrb = {})
          atrb[:caption] = 'Internal Commands'
          super
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
      # External Command Group
      class Group < Group
        def initialize(cfg, atrb = {})
          cfg[:caption] ||= 'External Commands'
          super
          dbi = type?(@cfg[:dbi], Dbi)
          @cfg['ver'] ||= dbi['version']
          # Set items by DB
          cdb = dbi[:command]
          idx = cdb[:index]
          @group=@displist.group.init_sub('==', 6)
          cdb[:group].each do|gid,gat|
            sg = @group.add_sub(gid,gat['caption'])
            gat[:members].each do|id|
              sg.put(id,idx[id]['label'])
              add_item(id, cdb, idx[id])
            end
          end
          init_alias(cdb, idx)
          @displist.reset!
        end

        def init_alias(cdb, idx)
          return unless cdb[:alias]
          sg = @group.add_sub('gal','Alias')
          cdb[:alias].each do|id, att|
            item = idx[att['ref']].dup
            item.update(att)
            sg.put(id,att['label'])
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
