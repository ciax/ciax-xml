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
          sym = _match_items(tbl, key, val)
          _make_sym(sym, key, val)
        end
      end

      def _make_sym(sym, key, val)
        msg = self[:msg][key] = format(sym[:msg] || 'N/A(%s)', val)
        cls = self[:class][key] = sym[:class] || 'alarm'
        verbose { "VIEW: msg(#{key}) is #{msg}/#{cls}" }
      end

      def _match_items(tbl, _key, val)
        tbl.each do|sym|
          res = _match_by_type(sym, val)
          if res
            verbose { format("VIEW:#{res} and [%s] -> #{sym[:msg]}", val, val) }
            return(sym)
          end
        end
        {}
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
        return unless /#{cri}/ =~ val || val == 'default'
        "Regexp:[#{cri}]"
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
