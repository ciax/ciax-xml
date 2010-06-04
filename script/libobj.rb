#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "libnumrange"

class Obj
  attr_reader :stat,:field,:property
  
  def initialize(obj)
    @doc=XmlDoc.new('odb',obj)
    if ref=@doc.property['ref']
      @ref=XmlDoc.new('odb',ref) 
    else
      @ref=@doc
    end
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
    session=select_cmd(cmd)
    warn session.attributes['label']
    session.each_element {|command|
      cmdary=get_cmd(command)
      $ver.msg("Exec(DDB):#{cmdary}")
      warn "CommandExec#{cmdary}"
      get_stat(yield(cmdary))
    }
  end
  
  def get_stat(dstat)
    return unless dstat
    @field.update(dstat)
    @doc.elements['//status'].each_element {|var| # var
      a=var.attributes
      id="#{@obj}:#{a['id']}"
      @stat[id]={'label'=>a['label'],'type'=>a['type'] }
      if ref=a['ref']
        var=@ref.elements["//status/[@id='#{ref}']"]
      end
      var.each_element {|e|
        case e.name
        when 'fields'
          val=get_val(e)
          $ver.msg("GetStat:#{id}=[#{val}]")
          @stat[id]['val']=val
        when 'symbol'
          get_symbol(e,@stat[id])
        end
      }
    }
    @stat['time']['val']=Time.at(@field['time'].to_f)
    @f.save_json(@stat)
  end
  
  private
  def select_cmd(id)
    e=@doc.select_id(id)
    if ref=e.attributes['ref']
      return @ref.select_id(ref)
    end
    return e
  end

  #Cmd Method
  def get_cmd(e)
    cmdary=[e.attributes['text']]
    e.each_element{|par|
      str=par.text
      if par.attributes['type'] == 'formula'
        func=par.text
        conv=func.gsub(/\$([\w]+)/) { @field[$1] }
        str=eval(conv).to_s
        $ver.msg("Function:(#{func})=#{str}")
      end
      cmdary << str
    }
    cmdary
  end

  #Stat Methods
  def get_val(e)
    val=String.new
    e.each_element {|f| #element(split and concat)
      a=f.attributes
      ref=a['ref'] || return
      data=@field[ref].clone || return
      $ver.msg("Convert:#{f.name.capitalize} Field (#{ref}) [#{data}]")
      case f.name
      when 'binary'
        val << (data.to_i >> a['bit'].to_i & 1).to_s
      when 'float'
        if n=a['decimal']
          data.insert(-1-n.to_i,'.')
        end
        val << format(f,data)
      when 'int'
        if a['signed']
          data=[data.to_i].pack('S').unpack('s').first
        end
        val << format(f,data)
      else
        val << data
      end
    }
    val
  end

  def get_symbol(e,set)
    e.each_element {|range|
      msg=range.attributes['msg']
      txt=range.text
      case range.name
      when 'range'
        if NumRange.new(txt) != set['val']
          $ver.msg("Symbol:Within [#{txt}](#{msg})?")
          next
        end
      when 'enum'
        if txt && txt != set['val']
          $ver.msg("Symbol:Matches (#{msg})?")
          next 
        end
      end
      add(range,set)
      break 1
    } || $ver.err("No Symbol selection")
    $ver.msg("Symbol:[#{set['msg']}] for [#{set['val']}]")
    set
  end

  # Common method
  def add(e,h,exclude=nil)
    h=Hash.new unless h
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
