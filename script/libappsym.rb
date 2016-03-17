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

      def ext_sym
        adbs = @dbi[:status]
        @symbol = adbs[:symbol] || {}
        @symdb = Sym::Db.pack(['share'] + adbs[:symtbl])
        self[:class] = {}
        self[:msg] = {}
        _init_procs(adbs)
        self
      end

      def _init_procs(adbs)
        @post_upd_procs << proc do # post process
          verbose { 'Propagate Status#upd -> Symbol#upd' }
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
        tbl.each do|sym|
          msg = _match_by_type(sym, val) || next
          self[:msg][key] = msg || "N/A(#{val})"
          self[:class][key] = sym[:class] || 'alarm'
          break
        end
      end

      def _match_by_type(sym, val)
        cri = sym[:val]
        case sym[:type]
        when 'numeric'
          _match_numeric(sym, cri, val)
        when 'range'
          _match_range(sym, cri, val)
        when 'pattern'
          _match_pattern(sym, cri, val)
        end
      end

      def _match_numeric(sym, cri, val)
        tol = sym[:tolerance]
        return unless cri.split(',').any? { |c| _within?(c, val, tol) }
        msg = format(sym[:msg], val)
        verbose { "VIEW:Numeric:[#{cri}+-#{tol}] and [#{val}] -> #{msg}" }
        msg
      end

      def _match_range(sym, cri, val)
        return unless _within?(cri, val)
        msg = format(sym[:msg], val)
        verbose { "VIEW:Range:[#{cri}] and [#{val}] -> #{msg}" }
        msg
      end

      def _match_pattern(sym, cri, val)
        return unless /#{cri}/ =~ val || val == 'default'
        msg = sym[:msg] || "N/A(#{val})"
        verbose { "VIEW:Regexp:[#{cri}] and [#{val}] -> #{msg}" }
        msg
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
      def ext_sym
        extend(Symbol).ext_sym
      end
    end

    if __FILE__ == $PROGRAM_NAME
      begin
        stat = Status.new
        stat.ext_sym
        stat.ext_file if STDIN.tty?
        puts stat.upd
      rescue InvalidARGS
        Msg.usage '[site] | < status_file'
      end
    end
  end
end
