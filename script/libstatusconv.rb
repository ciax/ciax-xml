#!/usr/bin/ruby
require 'libstatus'
# CIAX-XML
module CIAX
  # Application Layer
  module App
    # Convert Response
    class Status
      def ext_local_conv(field)
        extend(Conv).ext_local_conv(field)
      end

      # Response Module
      module Conv
        def self.extended(obj)
          Msg.type?(obj, Status)
        end

        def ext_local_conv(field)
          @field = type?(field, Frm::Field)
          type?(@dbi, Dbi)
          propagation(@field)
          ___init_cmt_procs
          self
        end

        private

        def ___init_cmt_procs
          init_time2cmt(@field)
          @cmt_procs << proc do
            @adbs.each do |id, hash|
              cnd = hash[:fields].empty?
              next if cnd && get(id)
              dflt = hash[:default] || ''
              self[:data][id] = cnd ? dflt : ___get_val(hash, id)
            end
          end
        end

        def ___get_val(hash, id)
          val = ___get_by_type(hash)
          verbose { "GetData[#{val}](#{id})" }
          val = ___conv_fomula(hash, val, id)
          val = hash[:format] % val if hash.key?(:format)
          val.to_s
        end

        def ___get_by_type(hash)
          case hash[:type]
          when 'binary'
            ___binstr2int(hash)
          when 'float'
            __get_num(hash).to_f
          when 'integer'
            __get_num(hash).to_i
          else
            hash[:fields].map { |e| __get_field(e) }.join
          end
        end

        def ___binstr2int(hash)
          bary = hash[:fields].map { |e| ___get_binstr(e) }
          binstr = case hash[:operation]
                   when 'uneven'
                     ___get_uneven(bary)
                   else
                     bary.join
                   end
          expr('0b' + binstr)
        end

        # Even(all 1 or 0) -> false, otherwise true
        def ___get_uneven(bary)
          ba = bary.inject { |a, e| a.to_i & e.to_i }
          bo = bary.inject { |a, e| a.to_i | e.to_i }
          (ba ^ bo).to_s
        end

        def __get_num(hash)
          ary = hash[:fields].map { |e| __get_field(e) }
          sign = /^[+-]$/ =~ ary[0] ? (ary.shift + '1').to_i : 1
          val = ary.map(&:to_f).inject(0) { |a, e| a + e }
          val /= ary.size if hash[:opration] == 'average'
          sign * val
        end

        def ___conv_fomula(hash, val, id)
          return val unless hash.key?(:formula)
          f = hash[:formula].gsub(/\$#/, val.to_s)
          val = expr(f)
          verbose { "Formula:#{f}(#{val})(#{id})" }
          val
        end

        def __get_field(e)
          fld = type?(e, Hash)[:ref] || give_up("No field Key in #{e}")
          val = @field.get(fld)
          # verbose(val.empty?) { "NoFieldContent in [#{fld}]" }
          val = e[:conv][val] if e.key?(:conv)
          val = val == e[:negative] ? '-' : '+' if /true|1/ =~ e[:sign]
          verbose { "GetField[#{fld}]=[#{val.inspect}]" }
          val
        end

        def ___get_binstr(e)
          val = __get_field(e).to_i
          inv = (/true|1/ =~ e[:inv])
          str = ___index_range(e[:bit]).map do |sft|
            bit = (val >> sft & 1)
            bit = -(bit - 1) if inv
            bit.to_s
          end.join
          verbose { "GetBit[#{str}]" }
          str
        end

        # range format n:m,l,..
        def ___index_range(str)
          str.split(',').map do |e|
            r, l = e.split(':').map { |n| expr(n) }
            Range.new(r, l || r).to_a
          end.flatten
        end
      end

      if __FILE__ == $PROGRAM_NAME
        require 'libfield'
        GetOpts.new('[site] | < field_file', options: 'r') do |opt, args|
          field = Frm::Field.new(args.shift).ext_local_file.load
          stat = Status.new(field[:id])
          stat.ext_local_conv(field).cmt
          puts opt[:r] ? stat.to_v : stat.path(args)
        end
      end
    end
  end
end
