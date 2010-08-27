#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "librerange"
require "libmodxml"
require "libiofile"
require "libconvstr"

class Obj < Hash
  include ModXml

  def initialize(obj)
    @odb=XmlDoc.new('odb',obj)
    if robj=@odb['ref']
      @rdb=XmlDoc.new('odb',robj)
      @odb.update(@rdb) {|k,o,r| o||r }
    end
  rescue RuntimeError
    abort $!.to_s
  else
    @f=IoFile.new(obj)
    begin
      self['stat']=@f.load_json
    rescue
      warn $!
      self['stat']={'time'=>{'label'=>'LAST UPDATE','type'=>'DATETIME'}}
    end
    @v=Verbose.new("odb/#{obj}".upcase)
    self['field']=Hash.new
    update(@odb)
    @obj=obj
    @cs=ConvStr.new(@v)
    @cs.var=self
    @gn=0
  end
  
  public
  def setcmd(line)
    cmd,*@cs.par=line.split(' ')
    @session=@odb.select_id('selection',cmd)
    a=@session.attributes
    @v.msg{"Exec(DDB):#{a['label']}"}
    @session=@rdb.select_id('selection',a['ref']) if a['ref']
    line
  rescue
    raise "== Command List ==\n#{$!}"
  end

  def objcom
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
    self['field'].update(dstat)
    @odb['status'].each_element{|g| group_var(g) }
    self['stat']['time']['val']=Time.at(self['field']['time'].to_f).to_s
    @f.save_json(self['stat'])
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
  def group_var(e)
    case e.name
    when 'group'
      @gn+=1
      e.each_element{|g| group_var(g) }
    when 'var'
      get_var(e)
    when 'repeat'
      @cs.repeat(e){|d| group_var(d) }
    end
  end

  def get_var(org) # //status/var
    va=[org]
    st={'group' => @gn }
    if ref=var_attr(va,'ref')
      @rdb['status'].each_element{|d|
        d.each_element_with_attribute('id',ref){|e|
          va << e
        }
      } || @v.err("No such id in ref")
    end
    id=var_attr(va,'id')
    st['label']=var_attr(va,'label')
    va.first.each_element{|e|
      case e.name
      when 'value'
        st['val']=get_val(e)
        @v.msg{"STAT:GetStatus:#{id}=[#{st['val']}]"}
      end
    }
    if sid=var_attr(va,'symbol')
      std_symbol(sid,st)
      if @odb['symbols']
        @odb['symbols'].each_element_with_attribute('id',sid){ |e|
          local_symbol(e,st)
        }
      end
    end
    self['stat'][id]=st
  end

  def get_val(e)
    ary=Array.new
    e.each_element {|dtype| #element(split and concat)
      a=dtype.attributes
      fld=var_attr([dtype],'field') || return
      fld=@cs.subnum(self['field'][fld]).to_s || return
      data=fld.clone
      # @v.msg{"STAT:Convert:#{dtype.name.capitalize} Field (#{fld}) [#{data}]"}
      case dtype.name
      when 'binary'
        bit=(data.to_i >> a['bit'].to_i & 1)
        bit = -(bit-1) if /true|1/ === a['inv']
       ary << bit.to_s
      when 'float'
        if n=a['decimal']
          data.insert(-1-n.to_i,'.')
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
    e.attributes['format'] % ary
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
      begin
        validate(enum,set['val'])
      rescue
        next
      end
      a.each{|k,v| set[k]=v }
      break true
    } || set.update({'msg'=>'N/A','hl'=>'warn'})
    @v.msg{"STAT:Symbol:[#{set['msg']}] for [#{set['val']}]"}
    set
  end

  def var_attr(va,str)
    va.each{|var|
      if a=var.attributes[str]
        return @cs.subnum(a).to_s
      end
    }
    nil
  end

end
