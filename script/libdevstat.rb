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
    @cc=Hash.new
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
  def cut_frame
    if l=attr['length']
      len=l.to_i
      warn "Too short (#{@frame.size-len})" if @frame.size < len
      return @frame.slice!(0,len)
    end
  end

  def check_cc
    return unless @cc
    if @cc[:given] === @cc[:calc]
      @v.msg("VerifyCC:OK [#{@cc[:given]}]")
    else
      @v.msg("VerifyCC:Mismatch [#{@cc[:given]}] != [#{@cc[:calc]}]")
    end
    @cc.clear
  end

  def verify(raw)
    @v.err "'Verify:No input file" unless raw
    str=decode(raw)
    pass=node_with_attr('type','pass').text
    node_with_text(str) {|e| #Match each case
      case e.attr['type']
      when 'pass'
        @v.msg('Verify:'+e.attr['msg']+"[#{str}]")
      when 'warn'
        @v.msg('Verify:'+e.attr['msg']+"[ (#{str}) for (#{pass}) ]")
      when 'error'
        @v.err('Verify:'+e.attr['msg']+"[ (#{str}) for (#{pass}) ]")
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

  def get_field
    str=String.new
    each_node {|e|
      case e.name
      when 'ccrange'
        e.ccrange
      when 'checkcode'
        @cc[:given]=e.decode(e.cut_frame)
        @v.msg("StoreCC: [#{@cc[:given]}]")
      when 'verify'
        e.verify(e.cut_frame)
      when 'assign'
        e.assign
      end
    }
    return str
  end

  def ccrange
    str=String.new
    each_node {|e|
      case e.name
      when 'verify'
        str << e.verify(e.cut_frame)
      when 'assign'
        str << e.assign
      end
    }
    @cc[:calc]=checkcode(str)
  end

  def decode(code)
    if upk=attr['unpack']
      code=code.unpack(upk).first
    end
    code.to_s
  end
  
end
