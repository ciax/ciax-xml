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
    @list=init_stat
  end
  
  public
  def get_stat
    @list.each{|line|
      begin
        @v.msg(1){"STAT:GetStatus:[#{line['id']}]"}
        get_val(line)
      ensure
        @v.msg(-1){"STAT:GetStatus:#{line['id']}=[#{@stat[line['id']]}]"}
      end
    }
    @stat['time']=Time.at(@field['time'].to_f).to_s
    self
  end
  
  private
  def init_stat
    list=[]
    @rep.each(@doc['status']){|e0|
      line={ :val => [] }
      e0.to_h.each{|k,v|
        line[k]=@rep.format(v)
      }
      e0.each{|e1|
        st={:type => e1.name}
        e1.to_h.each{|k,v|
          st[k] = @rep.subst(v)
        }
        line[:val] << st
      }
      @stat[line['id']]=''
      @v.msg{"STAT:Init #{line}"}
      list << line
    }
    list
  end

  def get_val(e0)
    id=e0['id']
    str=''
    e0[:val].each{|e1| #element(split and concat)
      fld=e1['ref'] || raise("No field Key")
      data=@field.get(fld) || raise("No field Value[#{fld}]")
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
    @stat[id]=str
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
