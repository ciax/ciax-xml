#!/usr/bin/env ruby
require 'libcmdremote'
module CIAX
  module CmdTree
    # Remote Command Domain
    module Remote
      # For External Command Domain
      # @cfg must contain [:dbi]
      # Content of Db::Item[:command][:index][id] will be merged in Item@cfg
      module Ext
        include CmdBase
        # External Command Group
        class Group < Group
          def initialize(spcfg, atrb = Hashx.new)
            atrb.get(:caption) { 'External Commands' }
            super
            cfg_err('No dbi in Ext::Group@cfg') unless @cfg.key?(:dbi)
            @disp_dic = @disp_dic.ext_grp
            ___init_form_ext(@cfg[:dbi].get(:command))
            @disp_dic.reset!
          end

          private

          # itm is from cdb
          def ___add_form(id, itm) # returns Form
            ___init_par(itm)
            _new_form(id, itm)
          end

          # command label can contain printf format (i.e. %s)
          # and are replaced with each parameter's label
          def ___init_par(itm)
            return unless itm.key?(:parameters)
            pars = CmdBase::ParArray.new(type?(itm[:parameters], Array))
            if (label = itm[:label])
              ary = pars.map { |e| e[:label] || 'str' }
              label.replace(format(label, *ary))
            end
            itm[:parameters] = pars
          end

          # Set items by DB
          def ___init_form_ext(cdb)
            cdb[:group].each do |gid, gat|
              sg = @disp_dic.add_grp(gid, gat[:caption], nil, gat[:rank])
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
              ___add_form(id, itm)
            end
          end

          # Unit Title will be set to Disp,
          # Unit Member will be removed from Disp instead
          def ___init_unit(cdb, guni, sg)
            return unless guni
            guni.each do |u|
              uat = cdb[:unit][u]
              next unless uat.key?(:title)
              ___make_unit_form(sg, uat, cdb[:index])
            end
          end

          def ___make_unit_form(sg, uat, index)
            umem = uat[:members]
            il = umem.map { |m| index[m][:label] }.join('/')
            sg.replace(sg - umem)
            sg.put_dummy(uat[:title], uat[:label] % il)
          end
        end
        # Ext Form
        class Form < Form
          def initialize(spcfg, atrb = Hashx.new)
            super
            @dbi = @cfg[:dbi]
          end
        end
        # Substitute string($+number) with parameters, which is called by others
        #  par={ val,range,format } or String
        #  str could include Math functions
        # Returns new object
        class Entity < Entity
          def deep_subst_par(data)
            case data
            when Array
              data.map { |v| deep_subst_par(v) }.extend(Enumx)
            when Hash
              data.each_with_object(Hashx.new) do |(k, v), r|
                r[k] = deep_subst_par(v)
              end
            else
              ___subst_par(data)
            end
          end

          private

          def ___subst_par(str) # subst by parameters ($1,$2...)
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
