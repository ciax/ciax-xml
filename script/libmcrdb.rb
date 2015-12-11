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
        if (inc = dbi[:include])
          dbi = super(inc).cover(dbi)
        end
        dbi
      end

      private

      def doc_to_db(doc)
        dbi = Dbi[doc[:attr]]
        @sites = []
        init_command(doc[:top], dbi)
        dbi[:sites] = @sites.uniq
        dbi
      end

      def arc_command(e0, gid)
        id = super
        itm = @idx[id]
        verbose { "MACRO:[#{id}]" }
        body = (itm[:body] ||= [])
        final = {}
        e0.each do|e1|
          atrb = e1.to_h
          _get_sites_(atrb)
          par2item(e1, itm) && next
          atrb[:type] = e1.name
          case e1.name
          when 'mesg'
            body << atrb
          when 'check', 'wait'
            body << make_condition(e1, atrb)
          when 'goal'
            body << make_condition(e1, atrb)
            final.update(atrb.extend(Enumx).deep_copy)[:type] = 'verify'
          when 'upd'
            body << atrb
            verbose { "UPDATE:[#{e1[:name]}]" }
          when 'cfg'
            atrb[:args] = getcmd(e1)
            atrb.delete(:name)
            body << atrb
            verbose { "CONFIG:[#{e1[:name]}]" }
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
            itm[:parameters] = [{type: 'str', list: atrb[:select].keys }]
            body << atrb
          end
        end
        body << final unless final.empty?
        id
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
      puts OPT[:r] ? dbi.to_v : dbi.path(ARGV)
    end
  end
end
