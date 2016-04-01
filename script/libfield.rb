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
      def subst(str, substed = []) # subst by field
        return str unless /\$\{/ =~ str
        enclose("Substitute from [#{str}]", 'Substitute to [%s]') do
          str.gsub(/\$\{(.+)\}/) do
            key = Regexp.last_match(1)
            ary = [*get(key)].map! { |i| expr(i) }
            Msg.give_up("No value for subst [#{key}]") if ary.empty?
            res = ary.join(',')
            substed << res
            res
          end
        end
      end

      # First id is taken as is (id:x:y) or ..
      # Get value for id with multiple dimention
      # - index should be numerical or formula
      # - ${id:idx1:idx2} => hash[id][idx1][idx2]
      def get(id)
        verbose { "Getting[#{id}]" }
        Msg.give_up('Nill Id') unless id
        return self[:data][id] if self[:data].key?(id)
        vname = []
        dat = id.split(':').inject(self[:data]) do|h, i|
          case h
          when Array
            begin
              i = expr(i)
            rescue SyntaxError, NoMethodError
              Msg.give_up("#{i} is not number")
            end
          when nil
            break
          end
          vname << i
          verbose { "Type[#{h.class}] Name[#{i}]" }
          verbose { "Content[#{h[i]}]" }
          h[i] || alert("No such Value #{vname.inspect} in :data")
        end
        verbose { "Get[#{id}]=[#{dat}]" }
        dat
      end

      # Replace value with pointer id
      def rep(id, val)
        conv = subst(val).to_s
        verbose { "Put[#{id}]=[#{conv}]" }
        case p = get(id)
        when Array
          _merge_ary_(p, conv.split(','))
        when String
          begin
            p.replace(expr(conv).to_s)
          rescue SyntaxError, NameError
            par_err('Value is not numerical')
          end
        end
        verbose { "Evaluated[#{id}]=[#{get(id)}]" }
        val
      ensure
        time_upd
        post_upd
      end

      def pick(keylist)
        Hashx.new(data: self[:data].pick(keylist))
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
        post_upd
      end

      private

      def _init_field_
        data = Hashx.new
        @dbi[:field].each do|id, val|
          data.put(id, val[:val] || Arrayx.new.skeleton(val[:struct]))
        end
        data
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
        puts Field.new(dbi)
      rescue InvalidARGS
        Msg.usage '(opt) [id]'
      end
    end
  end
end
