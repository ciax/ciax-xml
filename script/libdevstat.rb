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
    check_cc
    @field['time']="%.3f" % time.to_f
    @f.save_stat(@field)
  end

  def cmd_id
    super('rcv')
  end

  protected
  def verify
    raw=cut_frame
    @v.err "'Verify:No input file" unless raw
    str=decode(raw)
    if attr['checkcode']
      @var[:ccr]=str
      @v.msg("Store:CC [#{str}]")
      return raw
    end
    pass=node_with_attr('type','pass').text
    node_with_text(str) {|e| #Match each case
      msg='Verify:'+e.attr['msg']+" [#{str}]"
      case e.attr['type']
      when 'pass'
        @v.msg(msg)
      when 'warn'
        @v.wrn(msg+" for [#{pass}]")
      when 'error'
        @v.err(msg+" for [#{pass}]")
      end
      setcmd(e.attr['option']) if e.attr['option']
      return raw
    }
    @v.err "Verify:No error desctiption for #{self['label']}"
  end

  def assign
    raw=cut_frame
    if fld=attr['field']
      str=decode(raw) 
      @v.msg("Assign: [#{fld}] <- [#{str}]")
      @field[fld]=str
    end
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
          when 'assign'
            str << f.assign
          end
        }
        e.checkcode(str)
      when 'verify'
        e.verify
      when 'assign'
        e.assign
      end
    }
  end

  def check_cc
    return unless @var[:ccr]
    if @var[:ccr] === @var['cc']
      @v.msg("Verify:CC OK [#{@var[:ccr]}]")
    else
      @v.msg("Verify:CC Mismatch [#{@var[:ccr]}] != [#{@var['cc']}]")
    end
  end

  def cut_frame
    if l=attr['length']
      len=l.to_i
      warn "Too short (#{@frame.size-len})" if @frame.size < len
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
