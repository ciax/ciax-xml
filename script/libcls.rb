#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "libiofile"
require "libmodxml"
require "libconvstr"

class Cls
  include ModXml
  attr_reader :stat,:device

  def initialize(cls,obj=nil)
    @cdb=XmlDoc.new('cdb',cls)
  rescue RuntimeError
    abort $!.to_s
  else
    id=obj||cls
    @f=IoFile.new("status_#{id}")
    begin
      @stat=@f.load_stat
    rescue
      warn "----- Create status_#{id}.mar"
      @stat={ 'id'=>id, 'class' => cls }
    end
    @v=Verbose.new("cdb/#{id}".upcase)
    @field={}
    @cs=ConvStr.new(@v)
    @cs.stat=@stat
    @device=@cdb['device']
  end
  
  public

  def session(stm)
    @cs.par=stm.dup
    xpcmd=@cdb.select_id('commands',@cs.par.shift)
    @v.msg{"CMD:Exec(CDB):#{xpcmd.attributes['label']}"}
    xpcmd.each_element {|c|
      case c.name
      when 'parameters'
        pary=@cs.par.dup
        c.each_element{|d| #//par
          validate(d,pary.shift)
        }
      when 'statement'
        yield(get_cmd(c))
      when 'repeat'
        repeat_cmd(c){|d| yield d }
      end
    }
  end
  
  def get_stat(dstat)
    return unless dstat
    @field.update(dstat)
    @cdb['status'].each_element{|g|
      case g.name
      when 'value'
        get_val(g)
      when 'repeat'
        @cs.repeat(g){|e| get_val(e) }
      end
    }
    @stat['time']=Time.at(@field['time'].to_f).to_s
    @f.save_stat(@stat)
  end
  
  private
  #Cmd Method
  def repeat_cmd(e)
    @cs.repeat(e){ |f|
      case f.name
      when 'statement'
        yield(get_cmd(f))
      when 'repeat'
        repeat_cmd(f){ |g| yield g }
      end
    }
  end

  def get_cmd(e) # //stm
    stm=[]
    @v.msg(1){"CMD:GetCmd(DDB)"}
    begin
      e.each_element{|d| # //text or formula
        case d.name
        when 'text'
          str=d.text
          @v.msg{"CMD:GetText [#{str}]"}
        when 'formula'
          str=format(d,eval(@cs.sub_var(d.text)))
          @v.msg{"CMD:Calculated [#{str}]"}
        end
        stm << str
      }
      stm
    ensure
      @v.msg(-1){"CMD:Exec(DDB):#{stm}"}
    end
  end

  #Stat Methods
  def get_val(e)
    ary=Array.new
    id=@cs.sub_var(e.attributes['id'])
    @v.msg(1){"STAT:GetStatus:[#{id}]"}
    begin
      e.each_element {|dtype| #element(split and concat)
        a=dtype.attributes
        fld=@cs.sub_var(dtype.text) || raise("No field Key")
        data=@cs.acc_array(fld,@field) || raise("No field Value[#{fld}]")
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
