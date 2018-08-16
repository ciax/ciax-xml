#!/usr/bin/ruby
require 'libstatx'
require 'libdevdb'

module CIAX
  # Frame Layer
  module Frm
    # Frame Field
    class Field < Statx
      attr_reader :flush_procs
      attr_accessor :echo
      def initialize(dbi = nil)
        super('field', dbi, Dev::Db)
        # Proc for Terminate process of each individual commands
        #  (Set upper layer's update)
        @flush_procs = []
        self[:comerr] = false
        self[:data] = ___init_field unless self[:data]
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

      # First id is taken as is (id@x@y) or ..
      # Get value for id with multiple dimention
      # - index should be numerical or formula
      # - ${id@idx1@idx2} => hash[id][idx1][idx2]
      def get(id)
        verbose { "Getting[#{id}]" }
        cfg_err('Nill Id') unless id
        return self[:data][id] if self[:data].key?(id)
        vname = []
        dat = ___access_array(id, vname)
        verbose { "Get[#{id}]=[#{dat}]" }
        dat
      end

      # Replace value with pointer id
      #  value can be csv 'a,b,c,..'
      def repl(id, val)
        conv = subst(val).to_s
        verbose { "Put[#{id}]=[#{conv}]" }
        ___repl_by_case(get(id), conv)
        verbose { "Evaluated[#{id}]=[#{get(id)}]" }
        self
      ensure
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

      private

      def ___init_field
        data = Hashx.new
        @dbi[:field].each do |id, val|
          var = if (ary = val[:array])
                  ary.split(',')
                else
                  val[:val] || Arrayx.new.skeleton(val[:struct])
                end
          data.put(id, var)
        end
        data
      end

      def ___access_array(id, vname)
        id.split('@').inject(self[:data]) do |h, i|
          break unless h
          i = expr(i) if h.is_a? Array
          vname << i
          verbose { "Type[#{h.class}] Name[#{i}]" }
          verbose { "Content[#{h[i]}]" }
          h[i] || alert("No such Value #{vname.inspect} in :data")
        end
      end

      def ___repl_by_case(par, conv)
        case par
        when Array
          __merge_ary(par, conv.split(','))
        when String
          par.replace(expr(conv).to_s)
        end
      end

      def __merge_ary(p, r)
        r = [r] unless r.is_a? Array
        p.map! do |i|
          if i.is_a? Array
            __merge_ary(i, r.shift)
          else
            r.shift || i
          end
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[id]') do |_opts, args|
        puts Field.new(args.shift).to_r
      end
    end
  end
end
