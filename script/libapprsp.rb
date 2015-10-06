#!/usr/bin/ruby
require 'libstatus'

module CIAX
  module App
    module Rsp
      # @< (base),(prefix)
      def self.extended(obj)
        Msg.type?(obj, Status)
      end

      def ext_rsp(field)
        @field = type?(field, Frm::Field)
        type?(@dbi, Dbi)
        upd
        self
      end

      private
      def upd_core
        @adbs.each{|id, hash|
          enclose("GetStatus:[#{id}]", "GetStatus:#{id}=[%s]"){
            flds = hash[:fields]
            if flds.empty?
              @data[id] ||= (hash['default'] || '')
              next
            end
            case type = hash['type']
            when 'binary'
              bary = flds.map { |e| get_bin(e) }
              case hash['operation']
              when 'uneven'
                ba = bary.inject { |r, e| r.to_i & e.to_i }
                bo = bary.inject { |r, e| r.to_i | e.to_i }
                binstr = (ba ^ bo).to_s
              else
                binstr = bary.join
              end
              data = eval('0b' + binstr)
              verbose { "GetBinary[#{data}](#{id})" }
            else
              ary = flds.map { |e| get_field(e) }
              case type
              when 'float', 'integer'
                sign = (/^[+-]$/ === ary[0]) ? (ary.shift + '1').to_i : 1
                data = ary.map { |e| e.to_f }.inject(0) { |r, e| r + e }
                data = data / ary.size if hash['opration'] == 'average'
                case type
                when 'float'
                  data = (sign * data).to_f
                  verbose { "GetFloat[#{data}](#{id})" }
                when 'integer'
                  data = (sign * data).to_i
                  verbose { "GetInteger[#{data}](#{id})" }
                end
              else
                data = ary.join
              end
            end
            if hash.key?('formula')
              f = hash['formula'].gsub(/\$#/, data.to_s)
              data = eval(f)
              verbose { "Formula:#{f}(#{data})(#{id})" }
            end
            data = hash['format'] % data if hash.key?('format')
            @data[id] = data.to_s
          }
        }
        self['time'] = @field['time']
        verbose { "Update(#{self['time']})" }
        self
      end

      def get_field(e)
        type?(e, Hash)
        fld = e['ref'] || Msg.give_up("No field Key in #{e}")
        data = @field.get(fld)
        verbose(data.empty?) { "NoFieldContent in [#{fld}]" }
        data = e[:conv][data] if e[:conv]
        if /true|1/ === e['sign']
          verbose { "ConvertField[#{fld}]=[#{data.inspect}]" }
          if data == e['negative']
            data = '-'
          else
            data = '+'
          end
        end
        verbose { "GetField[#{fld}]=[#{data.inspect}]" }
        data
      end

      def get_bin(e)
        data = get_field(e).to_i
        inv = (/true|1/ === e['inv'])
        str = index_range(e['bit']).map{|sft|
          bit = (data >> sft & 1)
          bit = -(bit - 1) if inv
          bit.to_s
        }.join
        verbose { "GetBit[#{str}]" }
        str
      end

      # range format n:m,l,..
      def index_range(str)
        str.split(',').map{|e|
          r, l = e.split(':').map { |n| eval(n) }
          Range.new(r, l || r).to_a
        }.flatten
      end
    end

    class Status
      def ext_rsp(field)
        extend(App::Rsp).ext_rsp(field)
      end
    end

    if __FILE__ == $0
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
        field.ext_save.ext_load if STDIN.tty?
        stat = Status.new.setdbi(idb).ext_rsp(field)
        puts STDOUT.tty? ? stat : stat.to_j
      rescue InvalidID
        Msg.usage '[site] | < field_file'
      end
    end
  end
end
