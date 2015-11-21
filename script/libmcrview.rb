#!/usr/bin/ruby
require 'libparam'
require 'librecord'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Macro Man View
    class View < DataH
      def initialize(id, par, records = {})
        super('mcr')
        @par = type?(par, Parameter)
        @records = records
        @all_keys = []
        @ciddb = { '0' => 'user' }
        @id = id
      end

      def to_v
        _crnt_ ? _crnt_.to_v : _list_
      end

      def to_r
        _crnt_ ? _crnt_.to_r : super
      end

      def index
        n = @par.index
        if n
          opt = optlist(_crnt_.last['option']) if _crnt_.last
          "[#{n + 1}]#{opt}"
        else
          '[0]'
        end
      end

      def clear
        (keys - @all_keys).each { |id| delete(id) }
        self
      end

      private

      def upd_core
        pids = values.map { |r| r['pid'] }
        pids.delete('0')
        @all_keys.concat(pids + @par.list).uniq!
        @all_keys.each { |id| _upd_or_gen_(id) }
        clear
        self
      end

      def _upd_or_gen_(id)
        return @data[id].upd if @data.key?(id)
        r = put(id, get_rec(id))
        @ciddb[id] = r['cid'] unless @ciddb.key?(id)
      end

      def _crnt_
        @data[@par.current]
      end

      def get_rec(id)
        @records[id]
        # Record.new(id).ext_file.auto_load
        # Record.new(id).ext_http
      end

      def _list_
        page = ['<<< ' + Msg.color("Active Macros [#{@id}]", 2) + ' >>>']
        idx = 0
        @par.list.each_with_index { |id, idx| page << _item_(id, idx + 1) }
        page.join("\n")
      end

      def _item_(id, idx)
        rec = @data[id]
        title = "[#{idx}] (#{id})(by #{@ciddb[rec['pid']]})"
        msg = "#{rec['cid']} #{rec.step}"
        msg << _result_(rec)
        Msg.item(title, msg)
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
        par = Parameter.new.flush(ARGV)
        puts View.new('test', par).upd
      end
    end
  end
end
