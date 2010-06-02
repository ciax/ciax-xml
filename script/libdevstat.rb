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
    super(id,'recv')
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
    str=cut_frame(ary)
    label="ResponseCode:#{attr['label']}:"
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
      return
    }
    @v.wrn(label+":Unknown code [#{str}]")
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
    @v.err(label+'No field name') unless fld
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
    return unless @field['cc']
    if @field['cc'] === @var[:ccc]
      @v.msg("CheckCode OK [#{@field['cc']}]")
    else
      @v.msg("CheckCode Mismatch [#{@field['cc']}] != [#{@var[:ccc]}]")
    end
    @field.delete('cc')
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
    else
      @v.err("No frame length or delimiter")
    end
  end
  
  protected
  def decode(code)
    case upk=attr['unpack']
    when 'chr'
      str=code.unpack('C').first
    when 'bew'
      str=code.unpack('n').first
    when 'lew'
      str=code.unpack('v').first
    else
      return format(code)
    end
    @v.msg("Decode:unpack(#{upk}) [#{code}] -> [#{str}]")
    format(str)
  end
  
end
