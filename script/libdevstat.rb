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
    @verify_later=Hash.new
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

  def devstat(str)
    @v.err "No String" unless str
    @var.clear
    @frame=str
    get_field
    @verify_later.each {|e,s| e.verify(s)}
    @verify_later.clear
    @field['time']=Time.now.to_f.to_s
    @f.save_stat(@field)
  end

  def file_id
    super('rcv')
  end

  protected
  def cut_frame
    attr_with_key('length') {|l|
      len=l.to_i
      warn "Too short (#{@frame.size-len})" if @frame.size < len
      return @frame.slice!(0,len)
    }
  end

  def verify(raw)
    @v.err "No input file" unless raw
    str=decode(raw)
    begin
      pass=node_with_attr('type','pass').text
      node_with_text(str) {|e| #Match each case
        case e['type']
        when 'pass'
          @v.msg(e['msg']+"[#{str}]",1)
        when 'warn'
          @v.msg(e['msg']+"[ (#{str}) for (#{pass}) ]",1)
        when 'error'
          @v.err(e['msg']+"[ (#{str}) for (#{pass}) ]")
        end
        setcmd(e['option']) if e['option']
        return raw
      }
    rescue IndexError
      @v.err $! if @verify_later[self]
      @v.msg("#{$!} and code [#{str}] into queue",1)
      @verify_later[self]=raw
      return raw
    end
    @v.err "No error desctiption for #{self['label']}"
  end

  def assign
    raw=cut_frame
    attr_with_key('field') {|fld|
      str=decode(raw) 
      @v.msg("[#{fld}] <- [#{str}]",1)
      @field[fld]=str
    }
    raw
  end

  def get_field
    str=String.new
    each_node {|e|
      case e.name
      when 'ccrange'
        e.checkcode(e.get_field)
      when 'verify'
        str << e.verify(e.cut_frame)
      when 'assign'
        str << e.assign
      end
    }
    return str
  end

  private
  def decode(code)
    attr_with_key('unpack') {|val|
      code=code.unpack(val).first
    }
    code.to_s
  end
  
end
