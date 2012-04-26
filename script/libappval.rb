#!/usr/bin/ruby
require "libmsg"

class AppVal < Hash
  def initialize(adb,field)
    @v=Msg::Ver.new(self,9)
    Msg.type?(adb,AppDb)
    @field=Msg.type?(field,Field)
    @ads=adb[:status][:select]
    @fmt=adb[:status][:format]||{}
    @ads.keys.each{|k|
      self[k]||=''
    }
  end

  def upd
    @ads.each{|id,fields|
      begin
        @v.msg(1){"STAT:GetStatus:[#{id}]"}
        data=get_val(fields)
        data = @fmt[id] % data if @fmt.key?(id)
        self[id]=data.to_s
      ensure
        @v.msg(-1){"STAT:GetStatus:#{id}=[#{self[id]}]"}
      end
    }
    self['time']=@field.time
    @v.msg{"Update(#{self['time']})"}
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
    @v.msg{"GetBit[#{bit}]"}
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
    if e1['formula']
      f=e1['formula'].gsub(/\$#/,data.to_s)
      data=eval(f)
      @v.msg{"Formula:#{f}(#{data})"}
    end
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

if __FILE__ == $0
  require "libappdb"
  require "libfield"
  app=ARGV.shift
  ARGV.clear
  begin
    adb=AppDb.new(app)
    field=Field.new.load
    puts AppVal.new(adb,field).upd
  rescue UserError
    Msg.usage "[app] < field_file\n#{$!}"
  end
end
