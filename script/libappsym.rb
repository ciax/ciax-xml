#!/usr/bin/ruby
require 'libstatus'
require 'libsymdb'

# Status to App::Sym (String with attributes)
module CIAX
  # Application Layer
  module App
    # Symbol Converter
    module Symbol
      def self.extended(obj)
        Msg.type?(obj, Status)
      end

      def ext_local_sym
        adbs = @dbi[:status]
        @symbol = adbs[:symbol] || {}
        @symdb = Sym::Db.pack(['share'] + adbs[:symtbl])
        self[:class] = {}
        self[:msg] = {}
        _init_procs(adbs)
        self
      end

      def _init_procs(adbs)
        @cmt_procs << proc do # post process
          verbose { 'Propagate Status#cmt -> Symbol#store_sym' }
          store_sym(adbs[:index].dup.update(adbs[:alias] || {}))
        end
      end

      def store_sym(index)
        index.each do|key, hash|
          sid = hash[:symbol] || next
          tbl = _chk_tbl(sid) || next
          verbose { "ID=#{key},Table=#{sid}" }
          val = self[:data][hash[:ref] || key]
          _match_items(tbl, key, val)
        end
      end

      def _match_items(tbl, key, val)
        res = nil
        sym = tbl.find { |s| res = _match_by_type(s, val) } || _default_sym(tbl)
        msg = self[:msg][key] = format(sym[:msg] || 'N/A(%s)', val)
        cls = self[:class][key] = sym[:class] || 'alarm'
        verbose do
          format('VIEW(%s):%s and <%s> -> %s/%s', key, res, val, msg, cls)
        end
      end

      def _match_by_type(sym, val)
        cri = sym[:val]
        case sym[:type]
        when 'numeric'
          _match_numeric(cri, val, sym[:tolerance])
        when 'range'
          _match_range(cri, val)
        when 'pattern'
          _match_pattern(cri, val)
        end
      end

      def _match_numeric(cri, val, tol)
        return unless cri.split(',').any? { |c| _within?(c, val, tol) }
        "Numeric:[#{cri}+-#{tol}]"
      end

      def _match_range(cri, val)
        return unless _within?(cri, val)
        "Range:[#{cri}]"
      end

      def _match_pattern(cri, val)
        return unless /#{cri}/ =~ val
        "Regexp:[#{cri}]"
      end

      def _default_sym(tbl)
        tbl.find { |s| s[:type] == 'default' } || {}
      end

      def _chk_tbl(sid)
        tbl = @symdb[sid]
        return tbl if tbl
        alert("Table[#{sid}] not exist")
        nil
      end

      def _within?(cri, val, tol = nil)
        cri += ">#{tol}" if tol
        ReRange.new(cri) == val
      end
    end

    # Status class
    class Status
      def ext_local_sym
        extend(Symbol).ext_local_sym
      end
    end

    if __FILE__ == $PROGRAM_NAME
      begin
        stat = Status.new
        stat.ext_local_sym
        stat.ext_local_file if STDIN.tty?
        puts stat.cmt
      rescue InvalidARGS
        Msg.usage '[site] | < status_file'
      end
    end
  end
end
