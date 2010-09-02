#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "libiofile"
require "libmodxml"
require "libconvstr"
require "libstatsym"

module ObjStat
  #Stat Methods
  def stat_group(e)
    case e.name
    when 'group'
      @gn+=1
      e.each_element{|g| stat_group(g) }
    when 'title'
      get_var(e)
    when 'repeat'
      @cs.repeat(e){|d| stat_group(d) }
    end
  end

  def get_var(var) # //status/var
    st={'group' => @gn }
    a=var.attributes
    ref=@cs.sub_var(a['ref'])
    st['title']=@cs.sub_var(var.text)
    st['val']=@value[ref]
    @v.msg{"STAT:GetStatus:#{ref}=[#{st['val']}]"}
    st.update(@sym.get_symbol(a['symbol'],st['val']))
    st.update(@sym.get_level(a['level'],st['val']))
    @stat[ref]=st
  end

end

class Obj < Hash
  include ModXml
  include ObjStat
  attr_reader :stat

  def initialize(obj)
    @odb=XmlDoc.new('adb',obj)
  rescue RuntimeError
    abort $!.to_s
  else
    @f=IoFile.new(obj)
    begin
      @stat=@f.load_json
    rescue
      warn $!
      @stat={'time'=>{'label'=>'LAST UPDATE','type'=>'DATETIME'}}
    end
    @v=Verbose.new("odb/#{obj}".upcase)
    @value,@gn={},0
    @cs=ConvStr.new(@v)
    @cs.var={'value'=>@value,'stat'=>@stat }
    @odb['comm'].each_element{|e|
      self[e.name]=e.text
    }
    @sym=StatSym.new(@v)
  end
  
  public
  def setcmd(line)
    ca=line.split(' ')
    @session=@odb.select_id('command',ca.shift)
    @cs.set_par(ca)
    a=@session.attributes
    @v.msg{"Exec(ODB):#{a['label']}"}
    line
  rescue
    raise "== Command List ==\n#{$!}"
  end

  def alicmd
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
  
  def get_stat(value)
    return unless value
    @value.update(value)
    @odb['status'].each_element{|g| stat_group(g) }
    @stat['time']['val']=@value['time']
    @f.save_json(@stat)
  end
  
  private
  #Cmd Method
  def get_cmd(e) # //statement
    cmd=@session.a''
    argv=[]
    e.each_element{|d| # //argv
      str=eval(@cs.sub_var(d.text))
      @v.msg{"CMD:Evaluated [#{str}]"}
      argv << str
    }
    cmd = e.attributes['format'] % argv
    @v.msg{"Exec(DDB):[#{cmd}]"}
    cmd
  end

end
