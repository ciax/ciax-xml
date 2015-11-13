#!/usr/bin/ruby
require 'librecord'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Macro Man View
    class View < DataH
      def initialize(id, valid_keys)
        super('mcr')
        @valid_keys = valid_keys
        @all_keys = []
        @ciddb = { '0' => 'user' }
        @id = id
      end

      def to_v
        idx = 1
        page = ['<<< ' + Msg.color("Active Macros [#{@id}]", 2) + ' >>>']
        @data.each do|id, rec|
          title = "[#{idx}] (#{id})(by #{@ciddb[rec['pid']]})"
          msg = "#{rec['cid']} [#{rec.size}/#{rec['original_steps']}]"
          if rec['status'] == 'end'
            msg << "(#{rec['result']})"
          else
            msg << "(#{rec['status']})"
            msg << optlist(rec.last['option']) if rec.last
          end
          page << Msg.item(title, msg)
          idx += 1
        end
        page.join("\n")
      end

      def upd_core
        pids = values.map { |rec| rec['pid'] if rec['pid'].to_i > 0 }.compact
        @all_keys.concat(pids + @valid_keys).uniq!
        @all_keys.each do |id|
          next if @data.key?(id)
          rec = put(id, get_rec(id))
          @ciddb[id] = rec['cid'] unless @ciddb.key?(id)
        end
        self
      end

      def get_rec(id)
        Record.new(id).ext_file
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libgetopts'
      unless ARGV.empty?
        puts View.new('test', ARGV).upd
      else
        OPT.usage('[id] ..')
      end
    end
  end
end
