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
      super(id)
    rescue
      begin
        super('default')
      rescue
        @property.delete('cmd')
        raise "Send Only"
      end
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
  def status
    raw=cut_frame
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
    raw=cut_frame
    label="CheckCode:#{attr['label']} "
    str=decode(raw)
    @var[:ccr]=str
    @var[:cclabel]=label
    @v.msg(label+"Stored [#{str}]")
  end

  def verify
    raw=cut_frame
    label="Verify:#{attr['label']} "
    str=decode(raw)
    if text == str
      @v.msg(label+"OK [#{str}]")
      return raw
    else
      @v.err(label+"Mismatch [#{str}]")
    end
  end

  def assign
    raw=cut_frame
    fld=attr['field']
    label="Assign:#{attr['label']} "
    str=decode(raw) 
    @v.msg(label+"[#{fld}] <- [#{str}]")
    @field[fld]=str
    raw
  end

  private
  def get_field
    each_node {|e|
      case e.name
      when 'ccrange'
        str=String.new
        e.each_node {|f|
          case f.name
          when 'verify'
            str << f.verify
          when 'status'
            str << f.status
          when 'assign'
            str << f.assign
          end
        }
        e.checkcode(str)
      when 'cc_rsp'
        e.store_cc
      when 'verify'
        e.verify
      when 'status'
        e.status
      when 'assign'
        e.assign
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

  def cut_frame
    if l=attr['length']
      len=l.to_i
      @v.err("Too short (#{@frame.size-len})") if @frame.size < len
      return @frame.slice!(0,len)
    end
  end

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
