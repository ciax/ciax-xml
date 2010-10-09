#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "libiofile"
require "libmodxml"
require "libconvstr"

class Cls < Hash
  include ModXml
  attr_reader :stat

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
      warn $!
      @stat={ 'id'=>id }
    end
    @v=Verbose.new("cdb/#{id}".upcase)
    @field={}
    @cs=ConvStr.new(@v)
    @cs.var={'field'=>@field,'stat'=>@stat }
    self.update(@cdb)
  end
  
  public
  def setcmd(line)
    ca=line.split(/[: ]/)
    @session=@cdb.select_id('commands',ca.shift)
    @cs.par=ca
    @v.msg{"Exec(CDB):#{@session.attributes['label']}"}
    line
  rescue
    raise "== Command List ==\n#{$!}"
  end

  def clscom
    @session.each_element {|c|
      case c.name
      when 'parameters'
        pary=@cs.par.clone
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

  def get_cmd(e) # //statement
    argv=[]
    e.each_element{|d| # //argv
      str=@cs.sub_var(d.text)
      case d.name
      when 'eval'
        str=format(d,eval(str))
      end
      @v.msg{"CMD:Evaluated [#{str}]"}
      argv << str
    }
    cmd = argv.join(' ')
    @v.msg{"Exec(DDB):[#{cmd}]"}
    cmd
  end

  #Stat Methods
  def get_val(e)
    ary=Array.new
    id=@cs.sub_var(e.attributes['id'])
    @v.msg(1){"STAT:GetStatus:[#{id}]"}
    e.each_element {|dtype| #element(split and concat)
      a=dtype.attributes
      fld=@cs.sub_var(dtype.text) || raise
      data=@cs.sub_var("${field:#{fld}}") || raise
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
    @v.msg(-1){"STAT:GetStatus:#{id}=[#{value}]"}
    @stat[id]=value
  rescue
    @v.msg(-1){"STAT:Fail to Get Status:[#{id}]" }
  end

end
