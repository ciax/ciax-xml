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
      @stat={}
    end
    @v=Verbose.new("cdb/#{id}".upcase)
    @field={}
    @cs=ConvStr.new(@v)
    @cs.var={'field'=>@field,'stat'=>@stat }
    self.update(@cdb)
  end
  
  public
  def setcmd(line)
    cmd,*@cs.par=line.split(' ')
    @session=@cdb.select_id('commands',cmd)
    @v.msg{"Exec(DDB):#{@session.attributes['label']}"}
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
        @cs.repeat(c){|d| yield(get_cmd(d))}
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
  def get_cmd(e) # //statement
    cmd=''
    argv=[]
    e.each_element{|d| # //argv
      str=@cs.subnum(d.text).subpar.subvar.eval.to_s
      @v.msg{"CMD:Evaluated [#{str}]"}
      argv << str
    }
    cmd = e.attributes['format'] % argv
    @v.msg{"Exec(DDB):[#{cmd}]"}
    cmd
  end

  #Stat Methods
  def get_val(e)
    ary=Array.new
    e.each_element {|dtype| #element(split and concat)
      a=dtype.attributes
      fld=@cs.subnum(a['field']).to_s || return
      data=@field[fld] || return
      
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
    a=e.attributes
    id=@cs.subnum(a['id']).to_s
    value=a['format'] % ary
    @v.msg{"STAT:GetStatus:#{id}=[#{value}]"}
    @stat[id]=value
  end

end
