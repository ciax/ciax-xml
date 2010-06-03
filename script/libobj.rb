#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"

class Obj
  attr_reader :stat,:field,:property

  def initialize(obj)
    @doc=XmlDoc.new('odb',obj)
    @obj=@doc.property['id']
  rescue RuntimeError
    abort $!.to_s
  else
    @f=IoFile.new(@obj)
    begin
      @stat=@f.load_json
    rescue
      warn $!
      @stat={'time'=>{'label'=>'LAST UPDATE','type'=>'DATETIME'}}
    end
    $ver=Verbose.new("#{@doc.root.name}/#{@obj}".upcase)
    @field=Hash.new
    @property=@doc.property
  end
  
  public
  def objcom(line)
    cmd,par=line.split(' ')
    @field['par']=par
    session=control_id(cmd)
    warn session.attributes['label']
    session.each_element {|command|
      cmdary=get_cmd(command,@field)
      $ver.msg("Exec(DDB):#{cmdary}")
      warn "CommandExec#{cmdary}"
      get_stat(yield(cmdary))
    }
  end
  
  def get_stat(dstat)
    return unless dstat
    @field.update(dstat)
    @doc.elements['//status'].each_element {|var| # var
      id="#{@obj}:#{var.attributes['id']}"
      val=get_val(var,@field)
      $ver.msg("GetStat:#{id}=[#{val}]")
      @stat[id]=get_symbol(var,val)
    }
    @stat['time']['val']=Time.at(@field['time'].to_f)
    @f.save_json(@stat)
  end

  private
  def control_id(id)
    e=@doc.select_id('//controls/',id)
    if ref=e.attributes['ref']
      return control_id(ref)
    end
    return e
  end

  #Cmd Method
  def get_cmd(e,field)
    cmdary=[e.attributes['text']]
    e.each_element{|par|
      str=par.text
      if par.attributes['type'] == 'formula'
        func=par.text
        conv=func.gsub(/\$([\w]+)/) { field[$1] }
        $ver.msg("Function:(#{func})->(#{conv})")
        str=eval(func.gsub(/\$([\w]+)/) { field[$1] }).to_s
        $ver.msg("Function:(#{func})=#{str}")
      end
      cmdary << str
    }
    cmdary
  end

  #Stat Methods
  def get_val(e,field)
    val=String.new
    e.elements['./fields'].each_element {|f| #element(split and concat)
      ref=f.attributes['ref'] || return
      data=field[ref] || return
      $ver.msg("Convert:#{f.name.capitalize} Field (#{ref})")
      case f.name
      when 'binary'
        val << (data.to_i >> f.attributes['bit'].to_i & 1).to_s
      when 'float'
        if n=f.attributes['decimal']
          n=n.to_i
          data=data[0..-n-1]+'.'+data[-n..-1]
        end
        val << format(f,data)
      when 'int'
        if f.attributes['signed']
          data=[data.to_i].pack('S').unpack('s').first
        end
        val << format(f,data)
      else
        val << data
      end
    }
    val
  end

  def get_symbol(e,val)
    set={'val'=>val}
    add(e,set,'id')
    return(set) unless symbol=e.elements['./symbol']
    add(symbol,set)
    symbol.each_element {|range|
      msg=range.attributes['msg']
      txt=range.text
      case range.name
      when 'range_min'
        if txt != '-INF' && txt.to_f > val.to_f
          $ver.msg("Symbol:Greater than [#{txt}](#{msg})?")
          next 
        end
      when 'range_max'
        if txt != 'INF' && txt.to_f < val.to_f
          $ver.msg("Symbol:Less than [#{txt}](#{msg})?")
          next 
        end
      when 'enum'
        if txt && txt != val
          $ver.msg("Symbol:Matches (#{msg})?")
          next 
        end
      end
      add(range,set)
      break
    }
    $ver.msg("Symbol:[#{set['msg']}] for [#{set['val']}]")
    set
  end

  # Common method
  def add(e,h,exclude=nil)
    e.attributes.each{|k,v| h[k]=v if k != exclude }
  end

  def format(e,code)
    if fmt=e.attributes['format']
      str=fmt % code
      $ver.msg("Formatted code(#{fmt}) [#{code}] -> [#{str}]")
      code=str
    end
    code.to_s
  end

end
