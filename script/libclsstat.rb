#!/usr/bin/ruby
require "libverbose"
require "librepeat"

class ClsStat
  def initialize(doc,stat,field)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
    @doc,@stat,@field=doc,stat,field
    cls=doc['id']
    @stat.update({'time' => Time.now.to_s,'class' => cls })
    @v=Verbose.new("cdb/#{cls}/stat".upcase)
    @rep=Repeat.new
    set_stat{''}
  end
  
  public
  def get_stat
    set_stat{|e0| get_val(e0)}
    @stat['time']=Time.at(@field['time'].to_f).to_s
    self
  end
  
  private
  def set_stat
    @rep.each(@doc['status']){|e0|
      begin
        id=@rep.subst(e0['id'])
        @v.msg(1){"STAT:GetStatus:[#{id}]"}
        @stat[id]=yield e0
      ensure
        @v.msg(-1){"STAT:GetStatus:#{id}=[#{@stat[id]}]"}
      end
    }
    self
  end

  def get_val(e0)
    str=''
    e0.each{|e1| #element(split and concat)
      fld=@rep.subst(e1['ref']) || raise("No field Key")
      data=@field.get(fld) || raise("No field Value[#{fld}]")
      case e1.name
      when 'binary'
        loc=eval(@rep.subst(e1['bit']))
        bit=(data.to_i >> loc & 1)
        bit = -(bit-1) if /true|1/ === e1['inv']
        @v.msg{"GetBit[#{bit}]"}
        str << bit.to_s
      when 'float'
        sign=nil
        if /true|1/ === e1['signed']
          sign=(data[0] == "8")
          data=data[1..-1]
        end
        if n=e1['decimal']
          n=n.to_i
          data=data[0..(-1-n)]+'.'+data[-n..-1]
        end
        data=data.to_f
        data= -data if sign
        if e1.text
          f=e1.text.gsub(/\$#/,data.to_s)
          data=eval(f)
          @v.msg{"Formula:#{f}(#{data})"}
        end
        fmt=e1['format'] || "%f"
        str << fmt % data
      when 'int'
        data=data.to_i
        if /true|1/ === e1['signed']
          data= data > 0x7fff ? data - 0x10000 : data
        end
        fmt=e1['format'] || "%d"
        str << fmt % data
      else
        str << data
      end
    }
    str
  end
end
