#!/usr/bin/ruby
require 'libparam'
require 'librecord'
require 'libmcrlist'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Macro Man View
    class View < Varx
      def initialize(id, par, stat = List.new)
        super('mcr')
        @stat = type?(stat, List)
        @par = type?(par, Parameter)
        @list = Hashx.new
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
          opt = optlist(_crnt_.last[:option]) if _crnt_.busy? && _crnt_.last
          "[#{n + 1}]#{opt}"
        else
          '[0]'
        end
      end

      def clean
        (keys - @all_keys).each { |id| @list.delete(id) }
        self
      end

      private

      def upd_core
        pids = @list.values.map { |r| r[:pid] }
        pids.delete('0')
        @all_keys.concat(pids + @par.list).uniq!
        @all_keys.each { |id| _upd_or_gen_(id) }
        clean
        self
      end

      def _upd_or_gen_(id)
        return @list.get(id).upd if @list.key?(id)
        r = @list.put(id, get_rec(id))
        @ciddb[id] = r[:cid] unless @ciddb.key?(id)
      end

      def _crnt_
        @list.get(@par.current)
      end

      def get_rec(id)
        @stat.get(id)
      end

      def _list_
        page = ['<<< ' + colorize("Active Macros [#{@id}]", 2) + ' >>>']
        @par.list.each_with_index { |id, idx| page << _item_(id, idx + 1) }
        page.join("\n")
      end

      def _item_(id, idx)
        rec = @list[id]
        title = "[#{idx}] (#{id})(by #{@ciddb[rec[:pid]]})"
        msg = "#{rec[:cid]} #{rec.step_num}"
        msg << _result_(rec)
        itemize(title, msg)
      end

      def _result_(rec)
        if rec[:status] == 'end'
          "(#{rec[:result]})"
        else
          msg = "(#{rec[:status]})"
          msg << optlist(rec.last[:option]) if rec.last
          msg
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      if ARGV.empty?
        Msg.usage('[id] ..')
      else
        par = Parameter.new.flush(ARGV)
        puts View.new('test', par).upd
      end
    end
  end
end
