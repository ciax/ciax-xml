#!/usr/bin/ruby
require "librepeat"
require "libstat"
require "libmodxml"
require "libverbose"
require "libiofile"

class ClsStat < Stat
  include ModXml
  attr_reader :stat

  def initialize(cdb,id)
    @cdb=cdb
    @f=IoFile.new("status_#{id}")
    begin
      @stat=@f.load_stat
    rescue
      warn "----- Create status_#{id}.mar"
      @stat={ 'id'=>id, 'class' => cls }
    end
    @v=Verbose.new("cdb/#{cdb['id']}/stat".upcase)
    @rep=Repeat.new
    @field={}
  end
  
  public
  def get_stat(dstat)
    return unless dstat
    @field.update(dstat)
    @cdb['status'].each_element{|g|
      case g.name
      when 'value'
        get_val(g)
      when 'repeat'
        @rep.repeat(g){|e| get_val(e) }
      end
    }
    @stat['time']=Time.at(@field['time'].to_f).to_s
    @f.save_stat(@stat)
  end
  
  private
  def get_val(e)
    ary=Array.new
    id=@rep.sub_index(e.attributes['id'])
    id=sub_var(id)
    @v.msg(1){"STAT:GetStatus:[#{id}]"}
    begin
      e.each_element {|dtype| #element(split and concat)
        a=dtype.attributes
        fld=@rep.sub_index(dtype.text)
        fld=sub_var(fld) || raise("No field Key")
        data=acc_array(fld,@field) || raise("No field Value[#{fld}]")
        case dtype.name
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
      value=e.attributes['format'] % ary
      @stat[id]=value
    ensure
      @v.msg(-1){"STAT:GetStatus:#{id}=[#{value}]"}
    end
  end

end
