#!/usr/bin/ruby
require "libmsg"
require "libappdb"

class AppStat
  def initialize(adb,field,stat)
    @v=Msg::Ver.new("app/stat",9)
    @field=Msg.type?(field,Field)
    @adbs=adb[:select]
    @stat=Msg.type?(stat,Hash)
  end

  def upd
    @adbs.each{|id,fields|
      begin
        @v.msg(1){"STAT:GetStatus:[#{id}]"}
        @stat[id]=get_val(fields)
      ensure
        @v.msg(-1){"STAT:GetStatus:#{id}=[#{@stat[id]}]"}
      end
    }
    @stat['time']=Time.at(@field['time'].to_f).to_s
    self
  end

  private
  def get_val(fields)
    str=''
    fields.each{|e1| #element(split and concat)
      fld=e1['ref'] || Msg.abort("No field Key")
      data=@field.get(fld)||''
      case e1['type']
      when 'binary'
        str << binary(e1,data)
      when 'float'
        str << float(e1,data)
      when 'int'
        str << int(e1,data)
      else
        str << data
      end
    }
    str
  end

  def binary(e1,data)
    loc=eval(e1['bit'])
    bit=(data.to_i >> loc & 1)
    bit = -(bit-1) if /true|1/ === e1['inv']
    @v.msg{"GetBit[#{bit}]"}
    bit.to_s
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
    fmt=e1['format'] || "%f"
    fmt % data
  end

  def int(e1,data)
    data=data.to_i
    if /true|1/ === e1['signed']
      data= data > 0x7fff ? data - 0x10000 : data
    end
    fmt=e1['format'] || "%d"
    fmt % data
  end
end

if __FILE__ == $0
  require "libappdb"
  require "libfield"
  require "libview"
  app=ARGV.shift
  ARGV.clear
  begin
    adbs=AppDb.new(app,true)[:status]
    str=gets(nil) || exit
    field=Field.new.update_j(str)
    view=View.new(field['id'],adbs)
    AppStat.new(adbs,field,view['stat']).upd
    print view.upd.to_j
  rescue UserError
    abort "Usage: #{$0} [app] < field_file\n#{$!}"
  end
end
