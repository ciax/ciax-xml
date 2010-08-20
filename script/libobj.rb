#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "libnumrange"
require "libmodxml"
require "libiofile"

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
    @par=Array.new
  end
  
  public
  def setcmd(line)
    cmd,*@par=line.split(' ')
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
      when 'statement'
        yield(get_cmd(c))
      when 'repeat'
        repeat(c){|d| yield(get_cmd(d))}
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
        repeat(var){|d| get_var(d) }
      end
    }
    self['stat']['time']['val']=Time.at(self['field']['time'].to_f).to_s
    @f.save_json(self['stat'])
  end
  
  private
  #Cmd Method
  def get_cmd(e)
    cmd=''
    argv=[]
    e.each_element{|d|
      case d.name
      when 'cmd'
        cmd=d.text
      when 'par'
        str=eval(substitute(subnum(d.text)))
        @v.msg{"CMD:Evaluated [#{str}]"}
        argv << str
      end
    }
    cmd = cmd % argv if argv.size > 0
    @v.msg{"Exec(DDB):[#{cmd}]"}
    cmd
  end

  def substitute(str)
    return str unless /\$/ === str
    h=self.clone
    # Sub ${id} by hash[id]
    conv=str.gsub(/\$\{([\w:]+)\}/) {
      $1.split(':').each {|i| h=h[i] }
      h
    }
    @v.msg{"Substitute [#{str}] to [#{conv}]"}
    conv
  end

  #Stat Methods
  def get_var(var)
    a=var.attributes
    id=subnum(a['id'])
    st={'label'=> subnum(a['label']) }
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
      fld=subnum(a['field']) || return
      fld=subnum(self['field'][fld]) || return
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
      txt=enum.text
      case enum.name
      when 'range'
        next if NumRange.new(txt) != set['val']
        # @v.msg{"STAT:Symbol:Within([#{txt}] =~ [#{set['val']}])"}
      when 'case'
        # No text is default
        next if txt &&  /#{txt}/ !~ set['val']
        # @v.msg{"STAT:Symbol:Matches(/#{txt}/ =~ [#{set['val']}])"}
      end
      a.each{|k,v| set[k]=v }
      break true
    } || set.update({'msg'=>'N/A','hl'=>'warn'})
    @v.msg{"STAT:Symbol:[#{set['msg']}] for [#{set['val']}]"}
    set
  end

end
