#!/usr/bin/ruby
require 'libcmdremote'
module CIAX
  module Cmd
    # Remote Command Domain
    module Remote
      # For External Command Domain
      # @cfg must contain [:dbi]
      # Content of Dbi[:command][:index][id] will be merged in Item@cfg
      module Ext
        # External Command Group
        class Group < Group
          def initialize(cfg, atrb = {})
            atrb[:caption] ||= 'External Commands'
            super
            @displist = @displist.ext_grp
            _init_items(@cfg[:command])
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
            self
          end

          # Group Member will get into Index and Disp
          def _init_member_(cdb, mem, sg)
            mem.each do|id|
              itm = cdb[:index][id]
              sg.put_item(id, itm[:label])
              add_item(id, cdb, itm)
            end
          end

          # Unit Title will be set to Disp,
          # Unit Member will be removed from Disp instead
          def _init_unit_(cdb, guni, sg)
            return unless guni
            guni.each do|u|
              uat = cdb[:unit][u]
              if uat.key?(:title)
                umem = uat[:members]
                il = umem.map { |m| cdb[:index][m][:label] }.join('/')
                sg.put_dummy(uat[:title], uat[:label] % il)
                sg.replace(sg - umem)
              end
            end
          end
        end

        class Item < Item; end

        class Entity < Entity
          # Substitute string($+number) with parameters, which is called by others
          #  par={ val,range,format } or String
          #  str could include Math functions
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
end
