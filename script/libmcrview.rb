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
        _list_
      end

      private

      def upd_core
        pids = values.map { |rec| rec['pid'] if rec['pid'].to_i > 0 }.compact
        @all_keys.concat(pids + @valid_keys).uniq!
        @all_keys.each do |id|
          if @data.key?(id)
            @data[id].upd
          else
            rec = put(id, get_rec(id))
            @ciddb[id] = rec['cid'] unless @ciddb.key?(id)
          end
        end
        self
      end

      def get_rec(id)
        #Record.new(id).ext_file.auto_load
        Record.new(id).ext_http
      end

      def _list_
        idx = 1
        page = ['<<< ' + Msg.color("Active Macros [#{@id}]", 2) + ' >>>']
        @data.each do|id, rec|
          title = "[#{idx}] (#{id})(by #{@ciddb[rec['pid']]})"
          msg = "#{rec['cid']} #{rec.step}"
          msg << _result_(rec)
          page << Msg.item(title, msg)
          idx += 1
        end
        page.join("\n")
      end

      def _result_(rec)
        if rec['status'] == 'end'
          "(#{rec['result']})"
        else
          msg = "(#{rec['status']})"
          msg << optlist(rec.last['option']) if rec.last
          msg
        end
      end

    end

    if __FILE__ == $PROGRAM_NAME
      require 'libgetopts'
      if ARGV.empty?
        OPT.usage('[id] ..')
      else
        puts View.new('test', ARGV).upd
      end
    end
  end
end
