#!/usr/bin/env ruby
require 'libframe'
require 'libdevdb'

module CIAX
  # Frame Layer
  module Frm
    # Frame Field
    class Field < Statx
      include Dic
      attr_accessor :echo
      attr_reader :frame
      def initialize(dbi = nil)
        super('field', dbi, Dev::Db)
        # Proc for Terminate process of each individual commands
        #  (Set upper layer's update)
        self[:comerr] = false
        ext_dic(:data) { ___init_field }
        @frame = Stream::Frame.new(@dbi)
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
        return super if _dic.key?(id) && /@/ !~ id
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
      def pick(keyary, atrb = {})
        Hashx.new(atrb).update(data: _dic.pick(keyary))
      end

      # For propagate to Status update
      def flush
        verbose { 'Processing FlushProcs' }
        self[:comerr] = false
        cmt
      end

      def comerr
        self[:comerr] = true
        cmt
      end

      def ext_local_log
        @frame.ext_local_log
        self
      end

      private

      def ___init_field
        data = Hashx.new
        @dbi[:field].each do |id, db|
          data.put(id, ___field_var(db))
        end
        data
      end

      def ___field_var(db)
        return db[:array].split(',') if db.key?(:array)
        return Arrayx.new.skeleton(db[:struct]) if db.key?(:struct)
        return db[:val] if db.key?(:val)
        ''
      end

      def ___access_array(id, vname)
        id.split('@').inject(self[:data]) do |h, i|
          break unless h
          i = expr(i) if h.is_a? Array
          vname << i
          verbose { "Type[#{h.class}] Name[#{i}]" }
          verbose { "Content #{h[i].inspect}" }
          h[i] || alert('No such Value %S in :data', vname)
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
      Opt::Get.new('[id]', options: 'h') do |opt, args|
        puts Field.new(args).cmode(opt.host)
      end
    end
  end
end
