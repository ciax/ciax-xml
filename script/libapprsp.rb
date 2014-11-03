#!/usr/bin/ruby
require "libstatus"

module CIAX
  module App
    module Rsp
      # @< (base),(prefix)
      def self.extended(obj)
        Msg.type?(obj,Status)
      end

      def ext_rsp(field)
        @field=type?(field,Frm::Field)
        upd
        self
      end

      def upd
        @adbs.each{|id,hash|
          enclose("Rsp","GetStatus:[#{id}]","GetStatus:#{id}=[%s]"){
            flds=hash[:fields]||next
            begin
              case hash['type']
              when 'binary'
                data=eval('0b'+flds.map{|e| binstr(e) }.join)
                verbose("Rsp","GetBinary[#{data}](#{id})")
              when 'float'
                data=flds.map{|e| get_field(e)}.join.to_f
                verbose("Rsp","GetFloat[#{data}](#{id})")
              when 'integer'
                data=flds.map{|e| get_field(e)}.join.to_i
                verbose("Rsp","GetInteger[#{data}](#{id})")
              else
                data=flds.map{|e| get_field(e)}.join
              end
              if hash.key?('formula')
                f=hash['formula'].gsub(/\$#/,data.to_s)
                data=eval(f)
                verbose("Rsp","Formula:#{f}(#{data})(#{id})")
              end
              data = hash['format'] % data if hash.key?('format')
            end
            @data[id]=data.to_s
          }
        }
        self['time']=@field['time']
        verbose("Rsp","Update(#{self['time']})")
        self
      ensure
        post_upd
      end

      private
      def get_field(e)
        fld=e['ref'] || Msg.abort("No field Key")
        data=@field.get(fld)
        verbose("Rsp","NoFieldData in [#{fld}]") if data.empty?
        data=e[:conv][data] if e[:conv]
        if /true|1/ === e['sign']
          verbose("Rsp","ConvertFieldData[#{fld}]=[#{data.inspect}]")
          if data == e['negative']
            data="-"
          else
            data="+"
          end
        end
        verbose("Rsp","GetFieldData[#{fld}]=[#{data.inspect}]")
        data
      end

      def binstr(e)
        data=get_field(e).to_i
        inv=(/true|1/ === e['inv'])
        str=index_range(e['bit']).map{|sft|
          bit=(data >> sft & 1)
          bit = -(bit-1) if inv
          bit.to_s
        }.join
        verbose("Rsp","GetBit[#{str}]")
        str
      end

      # range format n:m,l,..
      def index_range(str)
        str.split(',').map{|e|
          r,l=e.split(':').map{|n| eval(n)}
          Range.new(r,l||r).to_a
        }.flatten
      end
    end

    class Status
      def ext_rsp(field)
        extend(App::Rsp).ext_rsp(field)
      end
    end

    if __FILE__ == $0
      require "libsitedb"
      require "libfrmrsp"
      require "libstatus"
      begin
        field=Frm::Field.new
        id=STDIN.tty? ? ARGV.shift : field.read['id']
        ldb=Site::Db.new.set(id)
        field.set_db(ldb[:fdb]).ext_rsp
        field.ext_file if STDIN.tty?
        stat=Status.new.set_db(ldb[:adb]).ext_file.ext_rsp(field).save
        puts STDOUT.tty? ? stat : stat.to_j
        Msg.msg("Status saved")
      rescue InvalidID
        Msg.usage "[site] | < field_file"
      end
    end
  end
end
