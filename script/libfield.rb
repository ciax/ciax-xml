#!/usr/bin/ruby
require 'libvarx'
require 'libdevdb'

module CIAX
  # Frame Layer
  module Frm
    # Frame Field
    class Field < Varx
      attr_reader :flush_procs
      attr_accessor :echo
      def initialize(dbi = nil)
        super('field')
        # Proc for Terminate process of each individual commands
        #  (Set upper layer's update)
        @flush_procs = []
        _setdbi(dbi, Dev::Db)
        self[:comerr] = false
        self[:data] = _init_field_ unless self[:data]
      end

      # Substitute str by Field data
      # - str format: ${key}
      # - output csv if array
      def subst(str) # subst by field
        return str unless /\$\{/ =~ str
        enclose("Substitute from [#{str}]", 'Substitute to [%s]') do
          str.gsub(/\$\{(.+)\}/) do
            key = Regexp.last_match(1)
            ary = [*get(key)].map! { |i| expr(i) }
            cfg_err("No value for subst [#{key}]") if ary.empty?
            ary.join(',')
          end
        end
      end

      # First id is taken as is (id:x:y) or ..
      # Get value for id with multiple dimention
      # - index should be numerical or formula
      # - ${id:idx1:idx2} => hash[id][idx1][idx2]
      def get(id)
        verbose { "Getting[#{id}]" }
        cfg_err('Nill Id') unless id
        return self[:data][id] if self[:data].key?(id)
        vname = []
        dat = _access_array(id, vname)
        verbose { "Get[#{id}]=[#{dat}]" }
        dat
      end

      # Replace value with pointer id
      #  value can be csv 'a,b,c,..'
      def repl(id, val)
        conv = subst(val).to_s
        verbose { "Put[#{id}]=[#{conv}]" }
        _repl_by_case(get(id), conv)
        verbose { "Evaluated[#{id}]=[#{get(id)}]" }
        val
      ensure
        time_upd
        cmt
      end

      # Structure is Hashx{ data:{ key,val ..} }
      def pick(keylist, atrb = {})
        Hashx.new(atrb).update(data: self[:data].pick(keylist))
      end

      # For propagate to Status update
      def flush
        verbose { 'Processing FlushProcs' }
        @flush_procs.each { |p| p.call(self) }
        self[:comerr] = false
        self
      end

      def seterr
        self[:comerr] = false
        cmt
      end

      def ext_local_file
        super.load
      end

      private

      def _init_field_
        data = Hashx.new
        @dbi[:field].each do|id, val|
          if (ary = val[:array])
            var = ary.split(',')
          else
            var = val[:val] || Arrayx.new.skeleton(val[:struct])
          end
          data.put(id, var)
        end
        data
      end

      def _access_array(id, vname)
        id.split(':').inject(self[:data]) do|h, i|
          break unless h
          i = expr(i) if h.is_a? Array
          vname << i
          verbose { "Type[#{h.class}] Name[#{i}]" }
          verbose { "Content[#{h[i]}]" }
          h[i] || alert("No such Value #{vname.inspect} in :data")
        end
      end

      def _repl_by_case(par, conv)
        case par
        when Array
          _merge_ary_(par, conv.split(','))
        when String
          par.replace(expr(conv).to_s)
        end
      end

      def _merge_ary_(p, r)
        r = [r] unless r.is_a? Array
        p.map! do|i|
          if i.is_a? Array
            _merge_ary_(i, r.shift)
          else
            r.shift || i
          end
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      begin
        dbi = Dev::Db.new.get(ARGV.shift)
        puts Field.new(dbi).to_r
      rescue InvalidARGS
        Msg.usage '(opt) [id]'
      end
    end
  end
end
