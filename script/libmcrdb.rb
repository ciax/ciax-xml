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
        @body = itm.get(:body) { [] }
        @vstep = Hashx.new
        _add_steps(e0, itm)
        _add_verify_step
        [id, itm]
      end

      def _add_steps(e0, itm)
        e0.each do|e1|
          atrb = Hashx.new(type: e1.name)
          atrb.update(e1.to_h)
          _get_sites_(atrb)
          par2item(e1, itm) && next
          _step_by_name(e1, atrb)
          _make_verify_step(atrb) if e1.name == 'goal'
          @body << atrb
        end
      end

      def _step_by_name(e1, atrb)
        case e1.name
        when 'check', 'wait', 'goal'
          _make_condition(e1, atrb)
        when 'cfg', 'exec', 'mcr'
          atrb[:args] = _get_cmd(e1)
        when 'select'
          atrb[:select] = _get_option(e1)
        end
        atrb.delete(:name)
      end

      def _make_verify_step(atrb)
        @vstep.update(atrb.extend(Enumx).deep_copy)[:type] = 'verify'
      end

      def _add_verify_step
        return if @vstep.empty?
        validate_par(@vstep)
        @body << @vstep
      end

      def _make_condition(e1, atrb)
        e1.each do|e2|
          hash = e2.to_h(:cri)
          hash[:cmp] = e2.name
          atrb.get(:cond) { [] } << hash
        end
      end

      def _get_cmd(e1)
        args = [e1[:name]]
        e1.each do|e2|
          args << e2.text
        end
        args
      end

      def _get_option(e1)
        options = {}
        e1.each do|e2|
          e2.each do|e3|
            options[e2[:val] || '*'] = _get_cmd(e3)
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
