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

      def ext_local_rsp(field)
        @field = type?(field, Frm::Field)
        type?(@dbi, Dbi)
        _init_upd_proc
        self
      end

      private

      def _init_upd_proc
        @upd_procs << proc do
          @adbs.each do|id, hash|
            cnd = hash[:fields].empty?
            next if cnd && get(id)
            self[:data][id] = cnd ? (hash[:default] || '') : _get_val(hash, id)
          end
        end
      end

      def time_upd
        super(@field[:time])
      end

      def _get_val(hash, id)
        val = _get_by_type(hash)
        verbose { "GetData[#{val}](#{id})" }
        val = _conv_fomula(hash, val, id)
        val = hash[:format] % val if hash.key?(:format)
        val.to_s
      end

      def _get_by_type(hash)
        case hash[:type]
        when 'binary'
          _binstr2int(hash)
        when 'float'
          _get_num(hash).to_f
        when 'integer'
          _get_num(hash).to_i
        else
          hash[:fields].map { |e| get_field(e) }.join
        end
      end

      def _binstr2int(hash)
        bary = hash[:fields].map { |e| _get_binstr(e) }
        case hash[:operation]
        when 'uneven'
          binstr = _get_uneven(bary)
        else
          binstr = bary.join
        end
        expr('0b' + binstr)
      end

      def _get_uneven(bary)
        ba = bary.inject { |a, e| a.to_i & e.to_i }
        bo = bary.inject { |a, e| a.to_i | e.to_i }
        (ba ^ bo).to_s
      end

      def _get_num(hash)
        ary = hash[:fields].map { |e| get_field(e) }
        sign = (/^[+-]$/ =~ ary[0]) ? (ary.shift + '1').to_i : 1
        val = ary.map(&:to_f).inject(0) { |a, e| a + e }
        val /= ary.size if hash[:opration] == 'average'
        sign * val
      end

      def _conv_fomula(hash, val, id)
        return val unless hash.key?(:formula)
        f = hash[:formula].gsub(/\$#/, val.to_s)
        val = expr(f)
        verbose { "Formula:#{f}(#{val})(#{id})" }
        val
      end

      def get_field(e)
        fld = type?(e, Hash)[:ref] || give_up("No field Key in #{e}")
        val = @field.get(fld)
        # verbose(val.empty?) { "NoFieldContent in [#{fld}]" }
        val = e[:conv][val] if e.key?(:conv)
        val = (val == e[:negative]) ? '-' : '+' if /true|1/ =~ e[:sign]
        verbose { "GetField[#{fld}]=[#{val.inspect}]" }
        val
      end

      def _get_binstr(e)
        val = get_field(e).to_i
        inv = (/true|1/ =~ e[:inv])
        str = index_range(e[:bit]).map do|sft|
          bit = (val >> sft & 1)
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
      def ext_local_rsp(field)
        extend(App::Rsp).ext_local_rsp(field)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libfield'
      require 'libstatus'
      begin
        field = Frm::Field.new
        stat = Status.new(field[:id])
        field.ext_local_file if STDIN.tty?
        puts stat.ext_local_rsp(field).upd
      rescue InvalidARGS
        Msg.usage '[site] | < field_file'
      end
    end
  end
end
