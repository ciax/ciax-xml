#!/usr/bin/ruby
require 'librecord'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Macro Man View
    class View < DataH
      def initialize(id, par, records = {})
        super('mcr')
        @par = par
        @valid_keys = par[:list]
        @records = records
        @all_keys = []
        @ciddb = { '0' => 'user' }
        @current = nil
        @id = id
      end

      def to_v
        @current = nil unless @data.key?(@current)
        @current ? @data[@current].to_v : _list_
      end

      # select id by number (1~max)
      #  return id otherwise nil
      def sel(num)
        num = _reg_crnt_(num)
        @current = (num && num > 0) ? @valid_keys[num - 1] : nil
        @par[:default] = @current
      end

      def current
        id = @current
        n = @valid_keys.index(id) if id
        if n
          "[#{n + 1}]"+optlist(@data[@current].last['option'])
        else
          @current = nil
          '[0]'
        end
      end

      def clear
        (keys - @all_keys).each { |id| delete(id) }
        @par[:default] = nil unless @valid_keys.include?(@par[:default])
        self
      end

      private

      def upd_core
        pids = values.map { |r| r['pid'] }
        pids.delete('0')
        @all_keys.concat(pids + @valid_keys).uniq!
        @all_keys.each { |id| _upd_or_gen_(id) }
        if @current
          @current = nil unless @valid_keys.include?(@current)
        end
        clear
        self
      end

      def _upd_or_gen_(id)
        return @data[id].upd if @data.key?(id)
        r = put(id, get_rec(id))
        @ciddb[id] = r['cid'] unless @ciddb.key?(id)
      end

      def get_rec(id)
        @records[id]
        # Record.new(id).ext_file.auto_load
        # Record.new(id).ext_http
      end

      def _list_
        page = ['<<< ' + Msg.color("Active Macros [#{@id}]", 2) + ' >>>']
        idx = 0
        @valid_keys.each { |id| page << _item_(id, idx += 1) }
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

      # num is regurated within 0 to max
      def _reg_crnt_(num)
        return if !num || num < 0
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
