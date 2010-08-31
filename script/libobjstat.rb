#!/usr/bin/ruby

module StatSymbol
  def get_symbol(sid,st)
    return st unless sid
    return st if std_symbol(sid,st)
    @odb.each{|db|
      db['symbols'].each_element_with_attribute('id',sid){ |e|
        return local_symbol(e,st)
      }
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
    when 'var'
      get_var(e)
    when 'repeat'
      @cs.repeat(e){|d| stat_group(d) }
    end
  end

  def get_var(org) # //status/var
    va=[org]
    st={'group' => @gn }
    if ref=org.attributes['ref']
      @odb.last['status'].each_element{|d|
        d.each_element_with_attribute('id',ref){|e| va << e }
      } || @v.err("No such id in ref")
    end
    a=var_select(va)
    st['label']=a['label']
    st['val']=get_val(a[:value])
    @v.msg{"STAT:GetStatus:#{a['id']}=[#{st['val']}]"}
    get_symbol(a['symbol'],st)
    @stat[a['id']]=st
  end

  def get_val(e)
    ary=Array.new
    e.each_element {|dtype| #element(split and concat)
      a=dtype.attributes
      fld=@cs.subnum(a['field']).to_s || return
      fld=@cs.subnum(@field[fld]).to_s || return
      data=fld.clone
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

  def var_select(va)
    h=Hash.new
    va.reverse.each{|var|
      var.attributes.each{|k,v|
        h[k]=@cs.subnum(v).to_s
      }
      var.each_element{|e| h[:value]=e }
    }
    h
  end

end
