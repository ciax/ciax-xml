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

      # Allows nil
      def get(id = nil)
        super(id || ENV['PROJ'] || ARGV.shift)
      end

      private

      def doc_to_db(doc)
        dbi = super
        @sites = []
        init_command(dbi)
        _add_group(doc[:group])
        dbi[:sites] = @sites.uniq
        dbi
      end

      def _add_item(e0, gid)
        id, itm = super
        verbose { "MACRO:[#{id}]" }
        body = (itm[:body] ||= [])
        final = Hashx.new
        e0.each do|e1|
          atrb = { type: e1.name }
          atrb.update(e1.to_h)
          _get_sites_(atrb)
          par2item(e1, itm) && next
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
            body << atrb
          end
        end
        unless final.empty?
          validate_par(final)
          body << final
        end
        [id, itm]
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

      def _get_sites_(atrb)
        @sites << atrb[:site] if atrb[:site] && /\$/ !~ atrb[:site]
        @sites.concat(atrb[:val].split(',')) if atrb[:label] == 'site'
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[id] (key) ..', 'r') do |opt, args|
        dbi = Db.new.get(args.shift)
        puts opt[:r] ? dbi.to_v : dbi.path(args)
      end
    end
  end
end
