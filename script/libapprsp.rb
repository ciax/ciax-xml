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
        self
      end

      def upd
        @adbs.each{|id,hash|
          enclose("AppRsp","GetStatus:[#{id}]","GetStatus:#{id}=[%s]"){
            flds=hash[:fields]||next
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
            @data[id]=data.to_s
          }
        }
        self['time']=@field['time']
        verbose("AppRsp","Update(#{self['time']})")
        super
      end

      private
      def get_field(e)
        fld=e['ref'] || Msg.abort("No field Key")
        data=@field.get(fld)||''
        verbose("AppRsp","GetFieldData[#{fld}]=[#{data}]")
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
      require "liblocdb"
      require "libfrmrsp"
      require "libstatus"
      Msg.usage "< field_file" if STDIN.tty?
      field=Frm::Field.new.read
      ldb=Loc::Db.new.set(field['id'])
      fdb=ldb[:frm]
      adb=ldb[:app]
      field.set_db(fdb).ext_rsp
      stat=Status.new.set_db(adb).ext_rsp(field).upd
      puts stat
      stat.save
      exit
    end
  end
end
