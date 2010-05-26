#!/usr/bin/ruby
require "libxmldev"
require "libiofile"

class DevStat < XmlDev

  attr_reader :field
  def initialize(doc)
    super(doc,'//rspframe')
    dev=doc.property['id']
    @f=IoFile.new(dev)
    begin
      @field=@f.load_stat
    rescue
      @field={'device'=>dev}
    end
  end

  def setcmd(id)
    raise "No id" unless id
    begin
      @sel=@doc.select_id('//rspframe/',id,'default')
      @property['cmd']=id
    rescue
      @property.delete('cmd')
      raise "Send Only"
    end
    self
  end

  def devstat(str,time=Time.now)
    @v.err "No String" unless str
    @var.clear
    @frame=str
    get_field
    verify_cc
    @field['time']="%.3f" % time.to_f
    @f.save_stat(@field)
  end

  def cmd_id
    super('rcv')
  end

  protected
  def rspcode(ary=nil)
    raw=cut_frame(ary)
    label="Status:#{attr['label']}:"
    str=decode(raw)
    each_node {|e| #Match each case
      next if e.text && e.text != str
      msg=label+e.attr['msg']+" [#{str}]"
      case e.attr['type']
      when 'pass'
        @v.msg(msg)
      when 'warn'
        @v.wrn(msg)
      when 'error'
        @v.err(msg)
      end
      setcmd(e.attr['option']) if e.attr['option']
      return raw
    }
    @v.wrn(label+":Unknown code [#{str}]")
    raw
  end

  def store_cc
    str=cut_frame(nil)
    label="CheckCode:#{attr['label']} "
    @var[:ccr]=str
    @var[:cclabel]=label
    @v.msg(label+"Stored [#{str}]")
  end
  
  def verify(ary=nil)
    str=cut_frame(ary)
    label="Verify:#{attr['label']} "
    if text == str
      @v.msg(label+"OK [#{str}]")
      return str
    else
      @v.err(label+"Mismatch [#{str}] != [#{text}]")
    end
  end
  
  def assign(fld,ary=nil)
    str=cut_frame(ary)
    label="Assign:#{attr['label']} "
    @v.msg(label+"[#{fld}] <- [#{str}]")
    @field[fld]=str
  end

  def repeat_assign(ary=nil)
    min=attr['min']||0
    max=attr['max']
    fmt=text
    @v.msg("Repeat Assign:[#{min} .. #{max}] for [#{fmt}]")
    (min.to_i .. max.to_i).each {|n|
      fld=fmt % n
      assign(fld,ary)
    }
  end
  
  private
  def get_field
    each_node {|e|
      case e.name
      when 'ccrange'
        ary=Array.new
        e.each_node {|f|
          case f.name
          when 'verify'
            f.verify(ary)
          when 'rspcode'
            f.rspcode(ary)
          when 'assign'
            f.assign(f.text,ary)
          when 'repeat_assign'
            f.repeat_assign(ary)
          end
        }
        e.checkcode(ary.join(''))
      when 'cc_rsp'
        e.store_cc
      when 'verify'
        e.verify
      when 'rspcode'
        e.rspcode
      when 'assign'
        e.assign(e.text)
      when 'repeat_assign'
        e.repeat_assign
      end
    }
  end
  
  def verify_cc
    return unless @var[:ccr]
    if @var[:ccr] === @var[:ccc]
      @v.msg(@var[:cclabel]+"OK [#{@var[:ccr]}]")
    else
      @v.msg(@var[:cclabel]+"Mismatch [#{@var[:ccr]}] != [#{@var[:ccc]}]")
    end
  end
  
  def cut_frame(ary)
    if l=attr['length']
      len=l.to_i
      @v.err("Too short (#{@frame.size-len})") if @frame.size < len
      raw=@frame.slice!(0,len)
      ary << raw if ary
      return decode(raw)
    elsif d=attr['delimiter']
      @frame.slice!(/$.+#{d}/)
    end
  end
  
  protected
  def decode(code)
    if upk=attr['unpack']
      if upk == 'hex'
        str=code.hex
      else
        str=code.unpack(upk).first
      end
      @v.msg("Decode:unpack(#{upk}) [#{code}] -> [#{str}]")
      code=str
    end
    code.to_s
  end
  
end
