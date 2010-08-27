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
    @cs=ConvStr.new(@v,self)
  end
  
  public
  def setcmd(line)
    cmd,*@cs.par=line.split(' ')
    @session=@odb.select_id('selection',cmd)
    a=@session.attributes
    @v.msg{"Exec(DDB):#{a['label']}"}
    if ref=a['ref']
      @session=@rdb.select_id('selection',ref)
    end
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
    @odb['status'].each_element {|var|
      case var.name
      when 'var'
        get_var(var)
      when 'repeat'
        @cs.repeat(var){|d| get_var(d) }
      end
    }
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
    begin
      cmd = e.attributes['format'] % argv
    rescue
      @v.err("No Parameter")
    end
    @v.msg{"Exec(DDB):[#{cmd}]"}
    cmd
  end


  #Stat Methods
  def get_var(var) # //status/var
    a=var.attributes
    id=@cs.subnum(a['id']).to_s
    st={'label'=> @cs.subnum(a['label']).to_s }
    if ref=a['ref']
      @rdb['status'].each_element_with_attribute('id',ref){|e| var=e } ||
        @rdb.list_id('status')
      a=var.attributes
    end
    st['trail']=a['trail']
    val=get_val(var)
    st['val']=val
    @v.msg{"STAT:GetStatus:#{id}=[#{val}]"}
    if sid=a['symbol']
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
    val=String.new
    e.each_element {|dtype| #element(split and concat)
      a=dtype.attributes
      fld=@cs.subnum(a['field']).to_s || return
      fld=@cs.subnum(self['field'][fld]).to_s || return
      data=fld.clone
      # @v.msg{"STAT:Convert:#{dtype.name.capitalize} Field (#{fld}) [#{data}]"}
      case dtype.name
      when 'binary'
        bit=(data.to_i >> a['bit'].to_i & 1)
        bit = -(bit-1) if /true|1/ === a['inv']
       val << bit.to_s
      when 'float'
        if n=a['decimal']
          data.insert(-1-n.to_i,'.')
        end
        val << format(dtype,data.to_f)
      when 'int'
        if /true|1/ === a['signed']
          data=data.to_i
          data= data > 0x7fff ? data - 0x10000 : data
        end
        val << format(dtype,data.to_i)
      else
        val << data
      end
    }
    val
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

end
