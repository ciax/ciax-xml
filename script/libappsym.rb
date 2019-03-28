#!/usr/bin/env ruby
require 'libappstat'
require 'libsymdb'

# Status to App::Sym (String with attributes)
module CIAX
  # Application Layer
  module App
    # Status class
    class Status
      def ext_local_sym(sdb = nil)
        extend(Symbol).ext_local_sym(sdb || Sym::Db.new)
      end
      # Symbol Converter
      module Symbol
        def self.extended(obj)
          Msg.type?(obj, Status)
        end

        def ext_local_sym(sdb)
          @symdb = type?(sdb, Sym::Db).get_dbi(['share'] + @adbs[:symtbl])
          @symbol = @adbs[:symbol] || {}
          ___init_procs
          self
        end

        def store_sym(index)
          index.each do |key, hash|
            sid = hash[:symbol] || next
            tbl = ___chk_tbl(sid) || next
            verbose { "ID=#{key},Table=#{sid}" }
            val = self[:data][hash[:ref] || key]
            ___match_items(tbl, key, val)
          end
          verbose { 'Conversion Status -> Symbol' }
          self
        end

        private

        def ___init_procs
          @cmt_procs.append(self, :sym) do # post process
            store_sym(@adbs[:index].dup.update(@adbs[:alias] || {}))
          end
        end

        def ___match_items(tbl, key, val)
          res = nil
          sym = tbl.find { |s| res = ___match_by_type(s, val) } ||
                ___default_sym(tbl)
          msg = self[:msg][key] = format(sym[:msg] || 'N/A(%s)', val)
          cls = self[:class][key] = sym[:class] || 'alarm'
          verbose do
            format('VIEW(%s):%s and <%s> -> %s/%s', key, res, val, msg, cls)
          end
        end

        def ___match_by_type(sym, val)
          cri = sym[:val]
          case sym[:type]
          when 'numeric'
            ___match_numeric(cri, val, sym[:tolerance])
          when 'range'
            ___match_range(cri, val)
          when 'pattern'
            ___match_pattern(cri, val)
          end
        end

        def ___match_numeric(cri, val, tol)
          return unless cri.split(',').any? { |c| _within?(c, val, tol) }
          "Numeric:[#{cri}+-#{tol}]"
        end

        def ___match_range(cri, val)
          return unless _within?(cri, val)
          "Range:[#{cri}]"
        end

        def ___match_pattern(cri, val)
          return unless /#{cri}/ =~ val
          "Regexp:[#{cri}]"
        end

        def ___default_sym(tbl)
          tbl.find { |s| s[:type] == 'default' } || {}
        end

        def ___chk_tbl(sid)
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
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Get.new('[site] | < status_file') do |_o, args|
        stat = Status.new(args.shift)
        stat.ext_local_sym
        stat.ext_local if STDIN.tty?
        puts stat.cmt
      end
    end
  end
end
