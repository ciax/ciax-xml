#!/usr/bin/ruby
require 'libdbcmd'
module CIAX
  # Macro Layer
  module Mcr
    # to_j for web select command
    module JList
      def to_j
        grp = self[:command][:group]
        hash = Hashx.new
        grp.each do |key, val|
          hash[key] = val[:members] if val[:rank] == '0'
        end
        hash.to_j
      end
    end

    # Macro Db
    class Db < DbCmd
      def initialize
        super('mdb')
      end

      # Allows nil, get Dbi
      def get(id = nil)
        super(id || ENV['PROJ'] || ARGV.shift).extend(JList)
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
        e0.each do |e1|
          atrb = Hashx.new(type: e1.name)
          atrb.update(e1.to_h)
          _get_sites_(atrb)
          par2item(e1, itm) && next
          _step_by_name(e1, atrb)
          _make_verify_step(e1, atrb)
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

      def _make_verify_step(e1, atrb)
        return unless e1.name == 'goal' && e1['verify'] =~ /true|1/
        @vstep.update(atrb.extend(Enumx).deep_copy)[:type] = 'verify'
      end

      def _add_verify_step
        return if @vstep.empty?
        validate_par(@vstep)
        @body << @vstep
      end

      def _make_condition(e1, atrb)
        e1.each do |e2|
          hash = e2.to_h(:cri)
          hash[:cmp] = e2.name
          atrb.get(:cond) { [] } << hash
        end
      end

      def _get_cmd(e1)
        args = [e1[:name]]
        e1.each do |e2|
          args << e2.text
        end
        args
      end

      def _get_option(e1)
        options = {}
        e1.each do |e2|
          e2.each do |e3|
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
      GetOpts.new('[id] (key) ..', '') do |_opt, args|
        dbi = Db.new.get
        puts dbi.path(args)
        puts dbi.to_j
      end
    end
  end
end
