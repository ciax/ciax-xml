#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "libnumrange"
require "libmodxml"
require "libiofile"

class Obj < Hash
  include ModXml
  attr_reader :stat,:field

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
      @stat=@f.load_json
    rescue
      warn $!
      @stat={'time'=>{'label'=>'LAST UPDATE','type'=>'DATETIME'}}
    end
    @v=Verbose.new("odb/#{obj}".upcase)
    @field=Hash.new
    update(@odb)
    @obj=obj
  end
  
  public
  def objcom(line)
    cmd,par=line.split(' ')
    @field['par']=par
    session=select_session(cmd)
    session.each_element {|command|
      cmdary=get_cmd(command)
      @v.msg{"Exec(DDB):#{cmdary.inspect}"}
      yield(cmdary)
    }
  end
  
  def get_stat(dstat)
    return unless dstat
    @field.update(dstat)
    @odb['status'].each_element {|var|
      get_var(var)
    }
    @stat['time']['val']=Time.at(@field['time'].to_f).to_s
    @f.save_json(@stat)
  end
  
  private
  def select_session(id)
    e=@odb.select_id('selection',id)
    a=e.attributes
    @v.msg{"Exec(DDB):#{a['label']}"}
    if ref=a['ref']
      return @rdb.select_id('selection',ref)
    else
      return e
    end
  end

  #Cmd Method
  def get_cmd(e)
    cmdary=Array.new
    e.each_element{|txt|
      str=substitute(txt.text,@field)
      if txt.name == 'eval'
        str=eval(str).to_s
        @v.msg{"CMD:Evaluated [#{str}]"}
      end
      cmdary << str
    }
    cmdary
  end

  #Stat Methods
  def get_var(var)
    a=var.attributes
    id="#{@obj}:#{a['id']}"
    st={'label'=>a['label'] }
    if ref=a['ref']
      @rdb['status'].each_element_with_attribute('id',ref){|e| var=e } ||
        @rdb.list_id('status')
      a=var.attributes
    end
    st['trail']=a['trail']
    val=get_val(var,@field)
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
    @stat[id]=st
  end

  def get_val(e,field)
    val=String.new
    e.each_element {|dtype| #element(split and concat)
      a=dtype.attributes
      fld=a['field'] || return
      fld=field[fld] || return
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
    if /^(normal|on-warn|off-warn|alarm|hide)$/ === sid
      st['type']='ENUM'
      st['msg']=(st['val']=='1') ? 'ON' : 'OFF'
      st['hl']=(sid === /hide|alarm/) ? 'hide' : 'normal'
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
    } || @v.err{"STAT:No Symbol selection"}
    @v.msg{"STAT:Symbol:[#{set['msg']}] for [#{set['val']}]"}
    set
  end

end
