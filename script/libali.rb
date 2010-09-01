#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "libiofile"
require "libmodxml"
require "libconvstr"

module StatSymbol
  def get_symbol(sid,st)
    return st unless sid
    return st if std_symbol(sid,st)
    @odb['symbols'].each_element_with_attribute('id',sid){ |e|
      return local_symbol(e,st)
    }
    st
  end

  # Built-in Symbol (normal,hide,on-warn,off-warn,alarm)
  def std_symbol(sid,st)
    if /^(normal|warn|off-warn|alarm|off-alarm|hide)$/ === sid
      st['type']='ENUM'
      st['msg']=(st['val']=='1') ? 'ON' : 'OFF'
      st['hl']=(/hide|alarm/ === sid) ? 'hide' : 'normal'
      case sid
      when 'warn'
        st['hl']='warn' if st['msg'] == 'ON'
      when 'off-warn'
        st['hl']='warn' if st['msg'] == 'OFF'
      when 'alarm'
        st['hl'] = 'alarm' if st['msg'] == 'ON'
      when 'off-alarm'
        st['hl'] = 'alarm' if st['msg'] == 'OFF'
      end
      st
    end
  end

  def local_symbol(e,set)
    set['type']=e.attributes['type']
    e.each_element {|enum|
      a=enum.attributes
      msg=a['msg']
      validate(enum,set['val']) rescue next
      a.each{|k,v| set[k]=v }
      break true
    } || set.update({'msg'=>'N/A','hl'=>'warn'})
    @v.msg{"STAT:Symbol:[#{set['msg']}] for [#{set['val']}]"}
    set
  end

end

module ObjStat
  include StatSymbol
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
    ref=@cs.subnum(a['ref']).to_s
    st['title']=@cs.subnum(var.text).to_s
    st['val']=@value[ref]
    @v.msg{"STAT:GetStatus:#{ref}=[#{st['val']}]"}
    get_symbol(a['symbol'],st)
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
  end
  
  public
  def setcmd(line)
    cmd,*@cs.par=line.split(' ')
    @session=@odb.select_id('command',cmd)
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
      str=@cs.subnum(d.text).subpar.subvar.eval.to_s
      @v.msg{"CMD:Evaluated [#{str}]"}
      argv << str
    }
    cmd = e.attributes['format'] % argv
    @v.msg{"Exec(DDB):[#{cmd}]"}
    cmd
  end

end
