#!/usr/bin/ruby
require "libverbose"
require "librepeat"
require "libstat"
require "libiofile"

class ClsStat
  def initialize(doc,id)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
    @doc=doc
    cls=doc['id']
    @stat=Stat.new(id,"status")
    @stat.update({ 'id'=>id, 'class' => cls })
    @v=Verbose.new("cdb/#{cls}/stat".upcase)
    @rep=Repeat.new
    @field=Stat.new(id,"field")
  end
  
  public
  def get_stat(field)
    return unless field
    @field.update(field)
    @rep.each(@doc['status']){|e0|
      get_val(e0)
    }
    @stat['time']=Time.at(@field['time'].to_f).to_s
    @stat.save
  end
  
  def stat(key=nil)
    @stat.get(key)
  end
  
  private
  def get_val(e0)
    id=@rep.subst(e0['id'])
    @v.msg(1){"STAT:GetStatus:[#{id}]"}
    str=''
    begin
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
          if n=e1['decimal']
            n=n.to_i
            data=data[0..(-1-n)]+'.'+data[-n..-1]
          end
          data=data.to_f
          if f=e1['formula']
            f=f.gsub(/\$#/,data.to_s)
            @v.msg{"Formula:#{f}(#{data})"}
            data=eval(f)
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
      @stat[id]=str
    ensure
      @v.msg(-1){"STAT:GetStatus:#{id}=[#{str}]"}
    end
  end

end
