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
      command.extend ObjCmd
      line=command.get_cmd(@field)
      $ver.msg("Exec(DDB):[#{line}]")
      warn "CommandExec[#{line}]"
      get_stat(yield(line))
    }
  end
  
  def get_stat(dstat)
    return unless dstat
    @field.update(dstat)
    @doc.elements['//status'].each_element {|var| # var
      var.extend ObjStat
      id="#{@obj}:#{var.attributes['id']}"
      set=Hash.new
      var.attributes.each{|k,v| set[k]=v unless k =='id' }
      val=var.get_val(@field)
      $ver.msg("GetStat:#{id}=[#{val}]")
      var.get_symbol(val,set)
      @stat[id]=set
    }
    @stat['time']['val']=Time.at(@field['time'].to_f)
    @f.save_json(@stat)
  end

  protected
  def control_id(id)
    if e=@doc.elements["//controls//[@id='#{id}']"]
      if ref=e.attributes['ref']
        return control_id(ref)
      end
      return e
    else
      @doc.list_id("//controls/")
      raise "No such ID"
    end
  end

end

module ObjCmd
  #Cmd methods
  public
  def get_cmd(field)
    devcmd=[attributes['text']]
    each_element{|par|
      if func=par.attributes['function']
        str=eval(func.gsub(/\$([\w]+)/) { field[$1] })
        $ver.msg("Function:(#{func})=#{str}")
      else
        str=par.attributes['text']
      end
      devcmd << str
    }
    devcmd.join(' ')
  end

end

module ObjStat
  #Stat Methods
  public
  def get_val(field)
    val=String.new
    elements['./fields'].each_element {|e| #element(split and concat)
      ref=e.attributes['ref'] || return
      data=field[ref] || return
      $ver.msg("Convert:#{e.name.capitalize} Field (#{ref})")
      case e.name
      when 'binary'
        val << (data.to_i >> e.attributes['bit'].to_i & 1).to_s
      when 'float'
        if n=e.attributes['decimal']
          n=n.to_i
          data=data[0..-n-1]+'.'+data[-n..-1]
        end
        val << format(data)
      when 'int'
        if e.attributes['signed']
          data=[data.to_i].pack('S').unpack('s').first
        end
        val << format(data)
      else
        val << data
      end
    }
    val
  end

  def get_symbol(val,set)
    set['val']=val
    symbol=elements['./symbol'] || return
    case symbol.attributes['type']
    when 'min_base'
      $ver.msg("Symbol:Compare by Minimum Base for [#{val}]")
      symbol.each_element {|range|
        base=range.text
        $ver.msg("Symbol:Greater than [#{base}]?")
        next if base.to_f > val.to_f
        range.attributes.each{|k,v| set[k]=v}
        break
      }
    when 'max_base'
      $ver.msg("Symbol:Compare by Maximum Base for [#{val}]")
      symbol.each_element {|range|
        base=range.text
        $ver.msg("Symbol:Less than [#{base}]?")
        next if base.to_f < val.to_f
        range.attributes.each{|k,v| set[k]=v}
        break
      }
    else
      symbol.each_element {|enum|
        next if enum.text && enum.text != val 
        enum.attributes.each{|k,v| set[k]=v}
      }
    end
  end

  private
  def add(h)
    attributes.each{|k,v| h[k]=v}
  end

  def format(code)
    if fmt=attributes['format']
      str=fmt % code
      $ver.msg("Formatted code(#{fmt}) [#{code}] -> [#{str}]")
      code=str
    end
    code.to_s
  end

end
