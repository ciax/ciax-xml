#!/usr/bin/ruby
require 'libcmdremote'
module CIAX
  module CmdTree
    # Remote Command Domain
    module Remote
      # For External Command Domain
      # @cfg must contain [:dbi]
      # Content of Dbi[:command][:index][id] will be merged in Item@cfg
      module Ext
        include CmdBase
        # External Command Group
        class Group < Group
          def initialize(cfg, atrb = Hashx.new)
            atrb.get(:caption) { 'External Commands' }
            super
            @displist = @displist.ext_grp
            ___init_items(@cfg[:command])
            @displist.reset!
          end

          # itm is from cdb
          def add_item(id, itm) # returns Item
            label = itm[:label]
            # command label can contain printf format (i.e. %s)
            # and are replaced with each parameter's label
            if label && itm[:parameters].is_a?(Array)
              ary = itm[:parameters].map { |e| e[:label] || 'str' }
              label.replace(format(label, *ary))
            end
            _new_item(id, itm)
          end

          private

          # Set items by DB
          def ___init_items(cdb)
            cdb[:group].each do |gid, gat|
              sg = @displist.put_grp(gid, gat[:caption], nil, gat[:rank])
              ___init_member(cdb, gat[:members], sg)
              ___init_unit(cdb, gat[:units], sg)
            end
            self
          end

          # Group Member will get into Index and Disp
          def ___init_member(cdb, mem, sg)
            mem.each do |id|
              itm = cdb[:index][id]
              sg.put_item(id, itm[:label])
              # [:parameters] is set here
              add_item(id, itm)
            end
          end

          # Unit Title will be set to Disp,
          # Unit Member will be removed from Disp instead
          def ___init_unit(cdb, guni, sg)
            return unless guni
            guni.each do |u|
              uat = cdb[:unit][u]
              next unless uat.key?(:title)
              ___make_unit_item(sg, uat, cdb[:index])
            end
          end

          def ___make_unit_item(sg, uat, index)
            umem = uat[:members]
            il = umem.map { |m| index[m][:label] }.join('/')
            sg.put_dummy(uat[:title], uat[:label] % il)
            sg.replace(sg - umem)
          end
        end

        class Item < Item; end

        # Substitute string($+number) with parameters, which is called by others
        #  par={ val,range,format } or String
        #  str could include Math functions
        class Entity < Entity
          def deep_subst(data)
            case data
            when Array
              data.map { |v| deep_subst(v) }
            when Hash
              data.each_with_object({}) { |(k, v), r| r[k] = deep_subst(v) }
            else
              ___subst_str(data)
            end
          end

          private

          def ___subst_str(str) # subst by parameters ($1,$2...)
            return str unless /\$([\d]+)/ =~ str
            # enclose("Substitute from [#{str}]", 'Substitute to [%s]') do
            # num = true
            res = str.gsub(/\$([\d]+)/) do
              i = Regexp.last_match(1).to_i
              # num = false if self[:parameters][i - 1][:type] != 'num'
              # verbose { "Parameter No.#{i} = [#{@par[i - 1]}]" }
              @par[i - 1] || Msg.cfg_err(" No substitute data ($#{i})")
            end
            Msg.cfg_err('Nil string') if res == ''
            res
            # end
          end
        end
      end
    end
  end
end
