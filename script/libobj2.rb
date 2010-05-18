#!/usr/bin/ruby
require "libxmldoc"
require "libxmldb"
require "libverbose"


class Element
  #Cmd methods
  public
  def get_cmd(field)
    devcmd=Array.new
    each_element{|text|
      if ref=text.attributes['ref']
        devcmd << text.operate(field[ref])
      else
        devcmd << text.text
      end
    }
    devcmd.join(' ')
  end

  protected
  def operate(str)
    if ope=attributes['operator']
      x=str.to_i
      y=text.hex
      case ope
      when 'and'
        str= x & y
      when 'or'
        str= x | y
      end
      $ver.msg("(#{x} #{ope} #{y})=#{str}",1)
    end
    str
  end

  #Stat Methods
  public
  def get_val(field)
    val=String.new
    elements['./fields'].each_element {|e| #element(split and concat)
      ref=e.attributes['ref'] || return
      data=field[ref] || return
      $ver.msg("#{e.name.capitalize} Field (#{ref})",1)
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
    enum=elements['./symbol'] || return
    case enum.attributes['type']
    when 'min_base'
      $ver.msg("Compare by Minimum Base for [#{val}]",1)
      enum.each_element {|range|
        base=range.text
        $ver.msg("Greater than [#{base}]?",1)
        next if base.to_f > val.to_f
        range.attributes.each{|k,v| set[k]=v}
        break
      }
    when 'max_base'
      $ver.msg("Compare by Maximum Base for [#{val}]",1)
      enum.each_element {|range|
        base=range.text
        $ver.msg("Less than [#{base}]?",1)
        next if base.to_f < val.to_f
        range.attributes.each{|k,v| set[k]=v}
        break
      }
    else
      enum.each_element_with_text(val) {|e|
        e.attributes.each{|k,v| set[k]=v}
      }
    end
  end

  private
  def format(code)
    if fmt=attributes['format']
      str=fmt % code
      $ver.msg("Formatted code(#{fmt}) [#{code}] -> [#{str}]",2)
      code=str
    end
    code.to_s
  end

end

class Obj
  attr_reader :stat,:field,:property

  def initialize(obj)
    begin
      @doc=XmlDoc.new('odb',obj)
      @obj=@doc.property['id']
    rescue RuntimeError
      abort $!.to_s
    end
    @f=IoFile.new(@obj)
    begin
      @stat=@f.load_json
    rescue
      warn $!
      @stat={'time'=>{'label'=>'LAST UPDATE','type'=>'DATETIME'}}
    end
    $ver=Verbose.new("#{@doc.root.name}/#{@obj}".upcase)
    @var=Hash.new
    @field=Hash.new
    @property=@doc.property
  end
  
  public
  def objcom(line)
    cmd,par=line.split(' ')
    @var['par']=par
    session=@doc.control_id(cmd)
    warn session.attributes['label']
    session.each_element {|command|
      line=command.get_cmd(@field)
      $ver.msg("Exec(DDB):[#{line}]",1)
      warn "CommandExec[#{line}]"
      get_stat(yield(line))
    }
  end
  
  protected
  
  def get_stat(dstat)
    return unless dstat
    @field.update(dstat)
    @doc.elements['//status'].each_element {|var| # var
      id="#{@obj}:#{var.attributes['id']}"
      set=Hash.new
      var.attributes.each{|k,v| set[k]=v}
      val=var.get_val(@field)
      set['val']=val
      $ver.msg("#{id}=[#{val}]",1)
      var.get_symbol(val,set)
      set.delete('id')
      @stat[id]=set
    }
    @stat['time']['val']=Time.at(@field['time'].to_f)
    @f.save_json(@stat)
  end
end
