#!/usr/bin/ruby
require 'libdatax'

module CIAX
  # Frame Layer
  module Frm
    # Frame Field
    class Field < DataH
      attr_reader :flush_procs
      attr_accessor :echo
      def initialize(init_struct = {})
        super('field', init_struct)
        # Proc for Terminate process of each individual commands (Set upper layer's update);
        @flush_procs = []
      end

      def setdbi(db)
        super
        # Field Initialize
        _init_field_ if @data.empty?
        self
      end

      # Substitute str by Field data
      # - str format: ${key}
      # - output csv if array
      def subst(str) # subst by field
        return str unless /\$\{/ =~ str
        enclose("Substitute from [#{str}]", 'Substitute to [%s]') do
          str.gsub(/\$\{(.+)\}/) do
            ary = [*get(Regexp.last_match(1))].map! { |i| expr(i) }
            Msg.give_up("No value for subst [#{Regexp.last_match(1)}]") if ary.empty?
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
        Msg.give_up('Nill Id') unless id
        return @data[id] if @data.key?(id)
        vname = []
        dat = id.split(':').inject(@data) do|h, i|
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

      # Replace value with mixed id
      def rep(id, val)
        pre_upd
        akey = id.split(':')
        Msg.par_err('No such Id') unless key?(akey.shift)
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
        post_upd
      end

      # For propagate to Status update
      def flush
        verbose { 'Processing FlushProcs' }
        @flush_procs.each { |p| p.call(self) }
        self
      end

      private

      def _init_field_
        @dbi[:field].each do|id, val|
          put(id, val[:val] || Arrayx.new.skeleton(val[:struct]))
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
      require 'libdevdb'
      stat = Field.new
      begin
        dbi = Dev::Db.new.get(ARGV.shift)
        stat.setdbi(dbi)
        puts stat.ext_file
      rescue InvalidID
        OPT.usage '(opt) [id]'
      end
    end
  end
end
