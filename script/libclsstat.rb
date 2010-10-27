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
    @cdb['status'].each_element{|e0|
      case e0.name
      when 'value'
        get_val(e0)
      when 'repeat'
        @rep.repeat(e0){|e1| get_val(e1) }
      end
    }
    @stat['time']=Time.at(@field['time'].to_f).to_s
    @stat.save_all
  end
  
  def stat
    Hash[@stat]
  end
  
  private
  def get_val(e0)
    ary=Array.new
    id=@rep.subst(e0.attributes['id'])
    @v.msg(1){"STAT:GetStatus:[#{id}]"}
    begin
      e0.each_element {|e1| #element(split and concat)
        a=e1.attributes
        fld=@rep.subst(e1.text) || raise("No field Key")
        data=@field.acc_stat(fld) || raise("No field Value[#{fld}]")
        case e1.name
        when 'binary'
          bit=(data.to_i >> a['bit'].to_i & 1)
          bit = -(bit-1) if /true|1/ === a['inv']
          ary << bit.to_s
        when 'float'
          if n=a['decimal']
            n=n.to_i
            data=data[0..(-1-n)]+'.'+data[-n..-1]
          end
          ary << data.to_f
        when 'int'
          if /true|1/ === a['signed']
            data=data.to_i
            data= data > 0x7fff ? data - 0x10000 : data
          end
          ary << data.to_i
        else
          ary << data
        end
      }
      value=e0.attributes['format'] % ary
      @stat[id]=value
    ensure
      @v.msg(-1){"STAT:GetStatus:#{id}=[#{value}]"}
    end
  end

end
