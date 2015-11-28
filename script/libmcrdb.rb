#!/usr/bin/ruby
require 'librepeat'
require 'libdb'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Db
    class Db < Db
      def initialize
        super('mdb')
      end

      def get(id = nil)
        dbi = super(id || PROJ || ARGV.shift)
        if inc = dbi[:include]
          dbi = super(inc).cover(dbi)
        end
        dbi
      end

      private

      def doc_to_db(doc)
        dbi = Dbi[doc[:attr]]
        @id = dbi[:id]
        @sites = []
        dbi[:command] = init_command(doc[:top])
        dbi[:sites] = @sites.uniq
        dbi
      end

      def init_command(mdbc)
        idx = {}
        grp = {}
        mdbc.each do|e|
          Msg.give_up('No group in mdbc') unless e.name == 'group'
          gid = e.attr2item(grp)
          arc_command(e, idx, grp[gid])
        end
        { group: grp, index: idx }
      end

      def arc_command(e, idx, grp)
        e.each do|e0|
          id = e0.attr2item(idx)
          verbose { "MACRO:[#{id}]" }
          item = idx[id]
          (grp[:members] ||= []) << id
          body = (item[:body] ||= [])
          final = {}
          e0.each do|e1|
            atrb = e1.to_h
            _get_sites_(atrb)
            par2item(e1, item) && next
            atrb[:type] = e1.name
            case e1.name
            when 'mesg'
              body << atrb
            when 'check', 'wait'
              body << make_condition(e1, atrb)
            when 'goal'
              body << make_condition(e1, atrb)
              final.update(atrb.extend(Enumx).deep_copy)[:type] = 'check'
            when 'exec'
              atrb[:args] = getcmd(e1)
              atrb.delete(:name)
              body << atrb
              verbose { "COMMAND:[#{e1[:name]}]" }
            when 'mcr'
              atrb[:args] = getcmd(e1)
              atrb.delete(:name)
              body << atrb
            when 'select'
              atrb[:select] = get_option(e1)
              atrb.delete(:name)
              body << atrb
            end
          end
          body << final unless final.empty?
        end
        idx
      end

      def make_condition(e1, atrb)
        e1.each do|e2|
          hash = e2.to_h(:cri)
          hash[:cmp] = e2.name
          (atrb[:cond] ||= []) << hash
        end
        atrb
      end

      def getcmd(e1)
        args = [e1[:name]]
        e1.each do|e2|
          args << e2.text
        end
        args
      end

      def get_option(e1)
        options = {}
        e1.each do|e2|
          e2.each do|e3|
            options[e2[:val] || '*'] = getcmd(e3)
          end
        end
        options
      end

      private

      def _get_sites_(atrb)
        @sites << atrb[:site] if atrb[:site] && /\$/ !~ atrb[:site]
        @sites.concat(atrb[:val].split(',')) if atrb[:label] == 'site'
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('r')
      begin
        dbi = Db.new.get(ARGV.shift)
      rescue InvalidID
        OPT.usage('[id] (key) ..')
      end
      puts OPT['r'] ? dbi.to_v : dbi.path(ARGV)
    end
  end
end
