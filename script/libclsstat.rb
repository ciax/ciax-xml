#!/usr/bin/ruby
require "libmodxml"
require "libverbose"
require "librepeat"
require "libstat"
require "libiofile"

class ClsStat
  include ModXml
  def initialize(cdb,id)
    @cdb=cdb
    cls=cdb['id']
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
    @rep.each(@cdb['status']){|e0|
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
    ary=Array.new
    id=@rep.subst(e0['id'])
    @v.msg(1){"STAT:GetStatus:[#{id}]"}
    begin
      e0.each{|e1| #element(split and concat)
        fld=@rep.subst(e1['ref']) || raise("No field Key")
        data=@field.get(fld) || raise("No field Value[#{fld}]")
        case e1.name
        when 'binary'
          loc=eval(@rep.subst(e1['bit']))
          bit=(data.to_i >> loc & 1)
          bit = -(bit-1) if /true|1/ === e1['inv']
          ary << bit.to_s
        when 'float'
          if n=e1['decimal']
            n=n.to_i
            data=data[0..(-1-n)]+'.'+data[-n..-1]
          end
          if f=e1['formula']
            data=eval(f.gsub(/\$#/,"#{data}.prec_f"))
          end
          ary << data.to_f
        when 'int'
          if /true|1/ === e1['signed']
            data=data.to_i
            data= data > 0x7fff ? data - 0x10000 : data
          end
          ary << data.to_i
        else
          ary << data
        end
      }
      value=e0['format'] % ary
      @stat[id]=value
    ensure
      @v.msg(-1){"STAT:GetStatus:#{id}=[#{value}]"}
    end
  end

end
