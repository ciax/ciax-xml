#!/usr/bin/env ruby
require 'libdbtree'
module CIAX
  # Macro Layer
  module Mcr
    # dic for web select command
    module CmdDic
      def web_select
        dic = Hashx.new
        self[:command][:group].each_value do |val|
          # Show only main macro commands (submacro is skipped)
          if val[:rank].to_i.zero?
            (dic[val[:caption]] ||= []).concat val[:members]
          end
        end
        dic
      end

      def label
        dic = Hashx.new
        self[:command][:index].each do |id, val|
          dic[id] = val[:label]
        end
        dic
      end
    end

    # Macro Db
    class Db < DbTree
      def initialize
        super('mdb')
      end

      # Allows nil, get Dbi
      def get(id = nil)
        super.extend(CmdDic)
      end

      private

      def _doc_to_db(doc)
        dbi = super
        @sites = []
        _init_command_db(dbi, doc[:group])
        dbi[:sites] = @sites.uniq
        dbi[:proj] = dbi[:id]
        dbi
      end

      def _add_item(e0, gid)
        id, itm = super
        verbose { "Command[#{id}]" }
        @body = itm.get(:body) { [] }
        @vstep = Hashx.new
        ___add_steps(e0, itm)
        ___add_verify_step
        [id, itm]
      end

      def ___add_steps(e0, itm)
        e0.each do |e1|
          atrb = Hashx.new(type: e1.name)
          atrb.update(e1.to_h)
          ___get_sites(atrb)
          _par2item(e1, itm) && next
          ___step_by_name(e1, atrb)
          ___make_verify_step(e1, atrb)
          @body << atrb
        end
      end

      def ___step_by_name(e1, atrb)
        case e1.name
        when 'check', 'wait', 'goal', 'bypass'
          ___make_condition(e1, atrb)
        when 'cfg', 'exec', 'mcr', 'upd'
          atrb[:args] = __get_cmd(e1)
        when 'select'
          atrb[:select] = ___get_option(e1)
        end
        atrb.delete(:name)
      end

      def ___make_verify_step(e1, atrb)
        return unless e1.name == 'goal' && e1['verify'] =~ /true|1/
        @vstep.update(atrb.extend(Enumx).deep_copy)[:type] = 'verify'
      end

      def ___add_verify_step
        return if @vstep.empty?
        _validate_par(@vstep)
        @body << @vstep
      end

      def ___make_condition(e1, atrb)
        e1.each do |e2|
          hash = e2.to_h
          hash[:cri] = hash.delete(:val)
          hash[:cmp] = e2.name
          atrb.get(:cond) { [] } << hash
        end
      end

      def __get_cmd(e1)
        args = [e1[:name] || 'upd']
        e1.each do |e2|
          args << e2.text
        end
        args
      end

      def ___get_option(e1)
        options = {}
        e1.each do |e2|
          e2.each do |e3|
            options[e2[:val] || '*'] = __get_cmd(e3)
          end
        end
        options
      end

      def ___get_sites(atrb)
        @sites << atrb[:site] if atrb[:site] && /\$/ !~ atrb[:site]
        @sites.concat(atrb[:val].split(',')) if atrb[:label] == 'site'
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libconf'
      ConfOpts.new('[id] (key) ..', options: 'j') do |cfg|
        dbi = Db.new.get(cfg.proj)
        puts cfg.opt[:j] ? dbi.web_select.to_j : dbi.path(cfg.args)
      end
    end
  end
end
