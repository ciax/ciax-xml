#!/usr/bin/ruby
require "libxmldoc"
require "libxmldb"
require "libverbose"

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
    @v=Verbose.new("#{@doc.root.name}/#{@obj}".upcase)
    @var=Hash.new
    @field=Hash.new
    @property=@doc.property
  end

  public
  def objcom(line)
    cmd,par=line.split(' ')
    controls=@doc.control_id(cmd)
    @var['par']=par
    controls.each_element{|session|
      cmd=Array.new
      session.each_element{|command|
        if ref=command.attributes['ref']
          cmd << operate(command,@field[ref])
        else
          cmd << command.text
        end
      }
      line=cmd.join(' ')
      @v.msg("Exec(DDB):[#{line}]",1)
      warn "CommandExec[#{line}]"
      if dstat=yield(line)
        @field.update(dstat)
        get_stat
        @stat['time']['val']=Time.at(@field['time'].to_f)
        @f.save_json(@stat)
      end
    }
  end

  protected
  def operate(e,str)
    if ope=e.attributes['operator']
      x=str.to_i
      y=e.text.hex
      case ope
      when 'and'
        str= x & y
      when 'or'
        str= x | y
      end
      @v.msg("(#{x} #{ope} #{y})=#{str}",1)
    end
    str
  end


  def get_stat
    @doc.elements['//status'].each_element {|var| # var
      set=Hash.new
      var.attributes.each{|k,v| set[k]=v}
      val=get_fieldset(var)
      set['val']=val
      @v.msg("#{var.attributes['id']}=[#{val}]",1)
      symbol(var,val,set)
      set.delete('id')
      id="#{@obj}:#{var.attributes['id']}"
      @stat[id]=set
    }
  end

  def get_fieldset(d)
    str=String.new
    d.elements['./fields'].each_element {|e| #element(split and concat)
      f=@field[e.attributes['ref']] || return
      case e.name
      when 'binary'
        str << (f.to_i >> e.attributes['bit'].to_i & 1).to_s
      when 'float'
        if n=e.attributes['decimal']
          n=n.to_i
          f=f[0..-n-1]+'.'+f[-n..-1]
        end
        str << format(e,f)
      when 'int'
        if e.attributes['signed']
          f=[f.to_i].pack('S').unpack('s').first
        end
        str << format(e,f)
      else
        str << f
      end
    }
    return str
  end


  def symbol(cn,val,set)
    enum=cn.elements['./symbol'] || return
    case enum.attributes['type']
    when 'min_base'
      @v.msg("Compare by Minimum Base for [#{val}]",1)
      enum.each_element {|range|
        base=range.text
        @v.msg("Greater than [#{base}]?",1)
        next if base.to_f > val.to_f
        range.attributes.each{|k,v| set[k]=v}
        break
      }
    when 'max_base'
      @v.msg("Compare by Maximum Base for [#{val}]",1)
      enum.each_element {|range|
        base=range.text
        @v.msg("Less than [#{base}]?",1)
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

  def format(e,code)
    if fmt=e.attributes['format']
      str=fmt % code
      @v.msg("Formatted code(#{fmt}) [#{code}] -> [#{str}]",2)
      code=str
    end
    code.to_s
  end

end
