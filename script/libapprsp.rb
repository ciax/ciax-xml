#!/usr/bin/ruby
require "libmsg"
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
          enclose("AppRsp","GetStatus:[#{id}]","GetStatus:#{id}=[%s]"){
            flds=hash[:fields]||next
            begin
              data=case hash['type']
                   when 'binary'
                     flds.inject(0){|sum,e| (sum << 1)+binary(e)}
                   when 'float'
                     flds.inject(0){|sum,e| sum+float(e)}
                   when 'integer'
                     flds.inject(0){|sum,e| sum+int(e)}
                   else
                     flds.inject(''){|sum,e| sum+get_field(e)}
                   end
              if hash.key?('formula')
                f=hash['formula'].gsub(/\$#/,data.to_s)
                data=eval(f)
                verbose("AppRsp","Formula:#{f}(#{data})")
              end
              data = hash['format'] % data if hash.key?('format')
            rescue NoData
              data=''
            end
            @data[id]=data.to_s
          }
        }
        self['time']=@field['time']
        verbose("AppRsp","Update(#{self['time']})")
      ensure
        post_upd
      end

      private
      def get_field(e)
        fld=e['ref'] || Msg.abort("No field Key")
        data=@field.get(fld)
        if data.empty?
          verbose("AppRsp","NoFieldData in [#{fld}]")
          raise(NoData)
        end
        verbose("AppRsp","GetFieldData[#{fld}]=[#{data.inspect}]")
        data
      end

      def binary(e1)
        data=get_field(e1)
        loc=eval(e1['bit'])
        bit=(data.to_i >> loc & 1)
        bit = -(bit-1) if /true|1/ === e1['inv']
        verbose("AppRsp","GetBit[#{bit}]")
        bit
      end

      def float(e1)
        data=get_field(e1)
        sign=nil
        # For Constant Length Data
        if /true|1/ === e1['signed']
          sign=(data[0] == "8")
          data=data[1..-1]
        end
        if n=e1['decimal']
          n=n.to_i
          data=data[0..(-1-n)]+'.'+data[-n..-1]
        end
        data=data.to_f
        # Numerical Data
        data= -data if sign
        verbose("AppRsp","GetFloat[#{data}]")
        data
      end

      def int(e1)
        data=get_field(e1).to_i
        if /true|1/ === e1['signed']
          data= data > 0x7fff ? data - 0x10000 : data
        end
        verbose("AppRsp","GetInteger[#{data}]")
        data
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
      rescue InvalidID
        Msg.usage "[site] | < field_file"
      end
    end
  end
end
