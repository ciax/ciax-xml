#!/usr/bin/ruby
require 'libstatus'
# CIAX-XML
module CIAX
  # Application Layer
  module App
    # Convert Response
    module Rsp
      def self.extended(obj)
        Msg.type?(obj, Status)
      end

      def ext_rsp(field)
        @field = type?(field, Frm::Field)
        type?(@dbi, Dbi)
        @pre_upd_procs << proc { self['time'] = @field['time'] }
        upd
        self
      end

      private

      def upd_core
        @adbs.each do|id, hash|
          enclose("GetStatus:[#{id}]", "GetStatus:#{id}=[%s]") do
            flds = hash[:fields]
            if flds.empty?
              @data[id] ||= (hash['default'] || '')
              next
            end
            case hash['type']
            when 'binary'
              data = conv_bin(hash)
            when 'float'
              data = conv_num(hash).to_f
            when 'integer'
              data = conv_num(hash).to_i
            else
              data = hash[:fields].map { |e| get_field(e) }.join
            end
            verbose { "GetData[#{data}](#{id})" }
            if hash.key?('formula')
              f = hash['formula'].gsub(/\$#/, data.to_s)
              data = expr(f)
              verbose { "Formula:#{f}(#{data})(#{id})" }
            end
            data = hash['format'] % data if hash.key?('format')
            @data[id] = data.to_s
          end
        end
        self
      end

      def conv_bin(hash)
        bary = hash[:fields].map { |e| get_bin(e) }
        case hash['operation']
        when 'uneven'
          ba = bary.inject { |a, e| a.to_i & e.to_i }
          bo = bary.inject { |a, e| a.to_i | e.to_i }
          binstr = (ba ^ bo).to_s
        else
          binstr = bary.join
        end
        expr('0b' + binstr)
      end

      def conv_num(hash)
        ary = hash[:fields].map { |e| get_field(e) }
        sign = (/^[+-]$/ =~ ary[0]) ? (ary.shift + '1').to_i : 1
        data = ary.map(&:to_f).inject(0) { |a, e| a + e }
        data /= ary.size if hash['opration'] == 'average'
        sign * data
      end

      def get_field(e)
        fld = type?(e, Hash)['ref'] || give_up("No field Key in #{e}")
        data = @field.get(fld)
        verbose(data.empty?) { "NoFieldContent in [#{fld}]" }
        data = e[:conv][data] if e.key?(:conv)
        data = (data == e['negative']) ? '-' : '+' if /true|1/ =~ e['sign']
        verbose { "GetField[#{fld}]=[#{data.inspect}]" }
        data
      end

      def get_bin(e)
        data = get_field(e).to_i
        inv = (/true|1/ =~ e['inv'])
        str = index_range(e['bit']).map do|sft|
          bit = (data >> sft & 1)
          bit = -(bit - 1) if inv
          bit.to_s
        end.join
        verbose { "GetBit[#{str}]" }
        str
      end

      # range format n:m,l,..
      def index_range(str)
        str.split(',').map do|e|
          r, l = e.split(':').map { |n| expr(n) }
          Range.new(r, l || r).to_a
        end.flatten
      end
    end

    # Add extend method in Status
    class Status
      def ext_rsp(field)
        extend(App::Rsp).ext_rsp(field)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libdevdb'
      require 'libinsdb'
      require 'libfrmrsp'
      require 'libstatus'
      begin
        field = Frm::Field.new
        id = STDIN.tty? ? ARGV.shift : field.read['id']
        idb = Ins::Db.new.get(id)
        ddb = Dev::Db.new.get(idb['frm_site'])
        field.setdbi(ddb).ext_rsp
        field.ext_file.load if STDIN.tty?
        stat = Status.new.setdbi(idb).ext_rsp(field)
        puts STDOUT.tty? ? stat : stat.to_j
      rescue InvalidID
        Msg.usage '[site] | < field_file'
      end
    end
  end
end
