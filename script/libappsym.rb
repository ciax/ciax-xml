#!/usr/bin/env ruby
require 'libstatus'
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

        # key format: category + ':' followed by key "data:key, msg:key..."
        # default category is :data if no colon
        def pick(keyary, atrb = {})
          keyary.each_with_object(Hashx.new(atrb)) do |str, h|
            cat, key = ___get_key(str)
            h.get(cat) { Hashx.new }[key] = get(cat)[key]
          end
        end

        def ext_local_sym(sdb)
          adbs = @dbi[:status]
          @symdb = type?(sdb, Sym::Db).get_dbi(['share'] + adbs[:symtbl])
          @symbol = adbs[:symbol] || {}
          self[:class] = {}
          self[:msg] = {}
          ___init_procs(adbs)
          self
        end

        def ___init_procs(adbs)
          @cmt_procs << proc do # post process
            verbose { 'Propagate Status#cmt -> Symbol#store_sym' }
            store_sym(adbs[:index].dup.update(adbs[:alias] || {}))
          end
        end

        def store_sym(index)
          index.each do |key, hash|
            sid = hash[:symbol] || next
            tbl = ___chk_tbl(sid) || next
            verbose { "ID=#{key},Table=#{sid}" }
            val = self[:data][hash[:ref] || key]
            ___match_items(tbl, key, val)
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

        def ___get_key(str)
          cat, key = str =~ /:/ ? str.split(':') : [:data, str]
          cat = cat.to_sym
          par_err("Invalid category (#{cat})") unless key?(cat)
          par_err("Invalid key (#{cat}:#{key})") if !key || !get(cat).key?(key)
          [cat, key]
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[site] | < status_file') do |_o, args|
        stat = Status.new(args.shift)
        stat.ext_local_sym
        stat.ext_local if STDIN.tty?
        puts stat.cmt
      end
    end
  end
end
