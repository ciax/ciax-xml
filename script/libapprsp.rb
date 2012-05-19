#!/usr/bin/ruby
require "libmsg"

module App
  module Rsp
    extend Msg::Ver
    def self.extended(obj)
      init_ver('AppRsp',2)
      Msg.type?(obj,Status::Var,Var::File)
    end

    def init(field)
      @field=Msg.type?(field,Field::Var)
      @ads=@db[:status][:select]
      @fmt=@db[:status][:format]||{}
      @fml=@db[:status][:formula]||{}
      @ads.keys.each{|k| @val[k]||='' }
      self
    end

    def upd
      @ads.each{|id,fields|
        begin
          Rsp.msg(1){"STAT:GetStatus:[#{id}]"}
          data=get_val(fields)
          if @fml.key?(id)
            f=@fml[id].gsub(/\$#/,data.to_s)
            data=eval(f)
            Rsp.msg{"Formula:#{f}(#{data})"}
          end
          data = @fmt[id] % data if @fmt.key?(id)
          @val[id]=data.to_s
        ensure
          Rsp.msg(-1){"STAT:GetStatus:#{id}=[#{@val[id]}]"}
        end
      }
      @val['time']=@field.get('time')
      Rsp.msg{"Rsp/Update(#{@val['time']})"}
      self
    end

    private
    def get_val(fields)
      num=0
      str=''
      fields.each{|e1| #element(split and concat)
        fld=e1['ref'] || Msg.abort("No field Key")
        data=@field.get(fld)||''
        case e1['type']
        when 'binary'
          num <<= 1
          num+=binary(e1,data)
        when 'float'
          num+=float(e1,data)
        when 'int'
          num+=int(e1,data)
        else
          str << data
        end
      }
      str.empty? ? num : str
    end

    def binary(e1,data)
      loc=eval(e1['bit'])
      bit=(data.to_i >> loc & 1)
      bit = -(bit-1) if /true|1/ === e1['inv']
      Rsp.msg{"GetBit[#{bit}]"}
      bit
    end

    def float(e1,data)
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
      data
    end

    def int(e1,data)
      data=data.to_i
      if /true|1/ === e1['signed']
        data= data > 0x7fff ? data - 0x10000 : data
      end
      data
    end
  end
end

if __FILE__ == $0
  require "libinsdb"
  require "libfield"
  require "libstatus"
  Msg.usage "< field_file" if STDIN.tty?
  field=Field::Var.new.load
  adb=Ins::Db.new(field['id']).cover_app
  stat=Status::Var.new.ext_file(adb).ext_save
  puts stat.extend(App::Rsp).init(field).upd
  stat.save
  exit
end
