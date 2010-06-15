#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "libnumrange"
require "libmodxml"

class Obj
  include ModXml
  attr_reader :stat,:field,:property
  
  def initialize(obj)
    @odb=XmlDoc.new('odb',obj)
    if robj=@odb['property']['ref']
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
    @property=@odb['property']
    @obj=obj
  end
  
  public
  def objcom(line)
    cmd,par=line.split(' ')
    @field['par']=par
    session=select_session(cmd)
    session.each_element {|command|
      cmdary=get_cmd(command)
      @v.msg("Exec(DDB):#{cmdary.inspect}")
      warn "CommandExec#{cmdary.inspect}"
      get_stat(yield(cmdary))
    }
  end
  
  def get_stat(dstat)
    return unless dstat
    @field.update(dstat)
    @odb['status'].each_element {|var|
      get_var(var)  
    }
    @stat['time']['val']=Time.at(@field['time'].to_f)
    @f.save_json(@stat)
  end
  
  private
  def select_session(id)
    @odb['selection'].each_element_with_attribute('id',id) {|e|
      a=e.attributes
      warn a['label']
      if ref=a['ref']
        @rdb['selection'].each_element_with_attribute('id',ref){|d| return d }
        @rdb.list_id('selection')
      end
      return e
    }
    @odb.list_id('selection')
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
        @v.msg("CMD:Function:(#{func})=#{str}")
      end
      cmdary << str
    }
    cmdary
  end

  #Stat Methods
  def get_var(var)
    a=var.attributes
    id="#{@obj}:#{a['id']}"
    @stat[id]={'label'=>a['label'] }
    if ref=a['ref']
      @rdb['status'].each_element_with_attribute('id',ref){|e| var=e } ||
        @rdb.list_id('status')
      a=var.attributes
    end
    val=get_val(var,@field)
    @stat[id]['val']=val
    @v.msg("STAT:GetStatus:#{id}=[#{val}]")
    if sid=a['symbol']
      @odb['symbols'].each_element_with_attribute('id',sid){ |e|
        get_symbol(e,@stat[id])
      }
    end
  end

  def get_val(e,field)
    val=String.new
    e.each_element {|dtype| #element(split and concat)
      a=dtype.attributes
      ref=a['ref'] || return
      data=field[ref].clone || return
      @v.msg("STAT:Convert:#{dtype.name.capitalize} Field (#{ref}) [#{data}]")
      case dtype.name
      when 'binary'
        val << (data.to_i >> a['bit'].to_i & 1).to_s
      when 'float'
        if n=a['decimal']
          data.insert(-1-n.to_i,'.')
        end
        val << format(dtype,data)
      when 'int'
        if a['signed']
          data=[data.to_i].pack('S').unpack('s').first
        end
        val << format(dtype,data)
      else
        val << data
      end
    }
    val
  end

  def get_symbol(e,set)
    set['type']=e.attributes['type']
    e.each_element {|range|
      a=range.attributes
      msg=a['msg']
      txt=range.text
      case range.name
      when 'range'
        if NumRange.new(txt) != set['val']
          @v.msg("STAT:Symbol:Within [#{txt}](#{msg})?")
          next
        end
      when 'enum'
        if txt && txt != set['val']
          @v.msg("STAT:Symbol:Matches (#{msg})?")
          next 
        end
      end
      a.each{|k,v| set[k]=v }
      break true
    } || @v.err("STAT:No Symbol selection")
    @v.msg("STAT:Symbol:[#{set['msg']}] for [#{set['val']}]")
    set
  end

end
