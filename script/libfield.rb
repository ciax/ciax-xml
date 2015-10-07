#!/usr/bin/ruby
require 'libdatax'

module CIAX
  module Frm
    class Field < DataH
      attr_reader :flush_procs
      attr_accessor :echo
      def initialize(init_struct = {})
        super('field', init_struct)
        # Proc for Terminate process of each individual commands (Set upper layer's update);
        @flush_procs = [proc { verbose { 'Processing FlushProcs' } }]
      end

      def setdbi(db)
        super
        # Field Initialize
        if @data.empty?
          @dbi[:field].each {|id, val|
            @data[id] = val['val'] || Arrayx.new.skeleton(val[:struct])
          }
        end
        self
      end

      # Substitute str by Field data
      # - str format: ${key}
      # - output csv if array
      def subst(str) # subst by field
        return str unless /\$\{/ === str
        enclose("Substitute from [#{str}]", 'Substitute to [%s]') {
          str.gsub(/\$\{(.+)\}/) {
            ary = [*get(Regexp.last_match(1))].map! { |i| eval(i) }
            Msg.give_up("No value for subst [#{Regexp.last_match(1)}]") if ary.empty?
            ary.join(',')
          }
        }
      end

      # First key is taken as is (key:x:y) or ..
      # Get value for key with multiple dimention
      # - index should be numerical or formula
      # - ${key:idx1:idx2} => hash[key][idx1][idx2]
      def get(key)
        verbose { "Getting[#{key}]" }
        Msg.give_up('Nill Key') unless key
        return @data[key] if @data.key?(key)
        vname = []
        dat = key.split(':').inject(@data) {|h, i|
          case h
          when Array
            begin
              i = eval(i)
            rescue SyntaxError, NoMethodError
              Msg.give_up("#{i} is not number")
            end
          when nil
            break
          end
          vname << i
          verbose { "Type[#{h.class}] Name[#{i}]" }
          verbose { "Content[#{h[i]}]" }
          h[i] || alert("No such Value [#{vname.join(':')}] in 'data'")
        }
        verbose { "Get[#{key}]=[#{dat}]" }
        dat
      end

      # Replace value with mixed key
      def rep(key, val)
        akey = key.split(':')
        Msg.par_err('No such Key') unless @data.key?(akey.shift)
        conv = subst(val).to_s
        verbose { "Put[#{key}]=[#{conv}]" }
        case p = get(key)
        when Array
          merge_ary(p, conv.split(','))
        when String
          begin
            p.replace(eval(conv).to_s)
          rescue SyntaxError, NameError
            par_err('Value is not numerical')
          end
        end
        verbose { "Evaluated[#{key}]=[#{@data[key]}]" }
        self['time'] = now_msec
        upd
        val
      end

      def flush
        @flush_procs.each { |p| p.call(self) }
        self
      end

      private
      def merge_ary(p, r)
        r = [r] unless Array === r
        p.map! {|i|
          if Array === i
            merge_ary(i, r.shift)
          else
            r.shift || i
          end
        }
      end
    end

    if __FILE__ == $PROGRAM_NAME
      f = Field.new({ 'a' => [['0'], '1'] })
      puts f.to_j
      s = ARGV.shift
      if s
        k, v = s.split('=')
        if v
          puts f.rep(k, v)
        else
          puts f.get(s)
        end
      end
    end
  end
end
