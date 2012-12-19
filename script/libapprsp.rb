#!/usr/bin/ruby
require "libmsg"
require "libstatus"

module App
  module Rsp
    extend Msg::Ver
    # @<< (upd_proc*)
    # @< db,(base),(prefix)
    def self.extended(obj)
      init_ver('AppRsp',2)
      Msg.type?(obj,Status::Var,Var::Load)
    end

    def ext_rsp(field)
      @field=Msg.type?(field,Field::Var)
      @ads=@db[:status][:select]
      @fmt=@db[:status][:format]||{}
      @fml=@db[:status][:formula]||{}
      @ads.keys.each{|k| self['val'][k]||='' }
      self
    end

    def upd
      @ads.each{|id,select|
        Rsp.msg(1){"STAT:GetStatus:[#{id}]"}
        flds=select[:fields]
        data=case select['type']
        when 'binary'
          flds.inject(0){|sum,e|
            (sum << 1)+binary(e)
          }
        when 'float'
          flds.inject(0){|sum,e|
            sum+float(e)
          }
        when 'integer'
          flds.inject(0){|sum,e|
            sum+int(e)
          }
        else
          flds.inject(''){|sum,e|
            sum+get_field(e)
          }
        end
        begin
          if @fml.key?(id)
            f=@fml[id].gsub(/\$#/,data.to_s)
            data=eval(f)
            Rsp.msg{"Formula:#{f}(#{data})"}
          end
          data = @fmt[id] % data if @fmt.key?(id)
          self['val'][id]=data.to_s
        ensure
          Rsp.msg(-1){"STAT:GetStatus:#{id}=[#{self['val'][id]}]"}
        end
      }
      self['time']=@field['time']
      Rsp.msg{"Rsp/Update(#{self['time']})"}
      self
    end

    private
    def get_field(e)
      fld=e['ref'] || Msg.abort("No field Key")
      @field.get(fld)||''
    end

    def binary(e1)
      data=get_field(e1)
      loc=eval(e1['bit'])
      bit=(data.to_i >> loc & 1)
      bit = -(bit-1) if /true|1/ === e1['inv']
      Rsp.msg{"GetBit[#{bit}]"}
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
      data
    end

    def int(e1)
      data=get_field(e1).to_i
      if /true|1/ === e1['signed']
        data= data > 0x7fff ? data - 0x10000 : data
      end
      data
    end
  end
end

class Status::Var
  def ext_rsp(field)
    extend(App::Rsp).ext_rsp(field)
  end
end

if __FILE__ == $0
  require "liblocdb"
  require "libfield"
  require "libstatus"
  Msg.usage "< field_file" if STDIN.tty?
  field=Field::Var.new.load
  adb=Loc::Db.new(field['id'])[:app]
  stat=Status::Var.new.ext_file(adb).ext_save
  puts stat.ext_rsp(field).upd
  stat.save
  exit
end
