#!/usr/bin/ruby
require "libverbose"
require "librepeat"

class ClsStat
  attr_reader :label
  def initialize(doc,stat,field)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
    @doc,@stat,@field=doc,stat,field
    @label={}
    @struct={}
    cls=doc['id']
    @stat.update({'time' => Time.now.to_s,'class' => cls })
    @v=Verbose.new("#{cls}/stat",2)
    @rep=Repeat.new
    init_stat
  end
  
  public
  def get_stat
    @struct.each{|id,fields|
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
  def init_stat
    list=[]
    @rep.each(@doc['status']){|e0|
      label={}
      e0.to_h.each{|k,v|
        label[k]=@rep.format(v)
      }
      id=label.delete('id')
      @label[id]=label
      @v.msg{"STAT:Init LABEL [#{id}] : #{label}"}
      fields=[]
      e0.each{|e1|
        st={:type => e1.name}
        e1.to_h.each{|k,v|
          st[k] = @rep.subst(v)
        }
        fields << st
      }
      @stat[id]=''
      @struct[id]=fields
    @v.msg{"STAT:Init VAL [#{id}] : #{fields}"}
    }
    self
  end

  def get_val(fields)
    str=''
    fields.each{|e1| #element(split and concat)
      fld=e1['ref'] || @v.abort("No field Key")
      data=@field.get(fld) || @v.warn("No field Value[#{fld}]")
      case e1[:type]
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
