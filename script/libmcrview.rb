#!/usr/bin/ruby
require 'librecord'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Macro Man View
    class View < DataH
      attr_reader :current
      def initialize(id, valid_keys)
        super('mcr')
        @valid_keys = valid_keys
        @all_keys = []
        @ciddb = { '0' => 'user' }
        @current = nil
        @id = id
      end

      def to_v
        @current = nil unless @data.key?(@current)
        @current ? @data[@current].to_v : _list_
      end

      def sel(num)
        num = _reg_crnt_(num)
        @current = @valid_keys[num - 1]
      end

      def num
        id = @current
        n = @data.keys.index(id) if id
        if n
          "[#{n+1}]"
        else
          @current = nil
          '[0]'
        end
      end

      def clear
        (keys - @all_keys).each{ |id| delete(id) }
        self
      end

      private

      def upd_core
        pids = values.map { |r| r['pid'] }
        pids.delete('0')
        @all_keys.concat(pids + @valid_keys).uniq!
        @all_keys.each { |id| _upd_gen_(id) }
        if @current
          @current = @valid_keys.last unless @valid_keys.include?(@current)
        end
        self
      end

      def _upd_gen_(id)
        return @data[id].upd if @data.key?(id)
        r = put(id, get_rec(id))
        @ciddb[id] = r['cid'] unless @ciddb.key?(id)
      end

      def get_rec(id)
        # Record.new(id).ext_file.auto_load
        Record.new(id).ext_http
      end

      def _list_
        idx = 1
        page = ['<<< ' + Msg.color("Active Macros [#{@id}]", 2) + ' >>>']
        @valid_keys.each do|id|
          rec = @data[id]
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

      def _reg_crnt_(num)
        num = 0 if num < 0
        num = @valid_keys.size if num > @valid_keys.size
        num
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
