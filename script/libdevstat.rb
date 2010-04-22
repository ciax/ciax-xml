#!/usr/bin/ruby
require "libmoddev"
require "libxmldb"
class DevStat < XmlDb
  include ModDev
  def initialize(doc)
    super(doc,'//rspframe')
    @field={'device'=>@property['id']}
    @verify_later=Hash.new
  end

  def devstat(str)
    @frame=str
    get_field
    @verify_later.each do |e,ele|
      e.verify(ele)
    end
    return @field
  end
  
  def node_with_id!(id)
    super(id) rescue raise("Send Only")
    self
  end

  protected
  def cut_frame
    len=@doc.attributes['length'].to_i
    warn "Too short (#{@frame.size-len})" if @frame.size < len
    return @frame.slice!(0,len)
  end

  def verify(raw)
    str=decode(raw)
    begin
      pass=node_with_attr('type','pass').text
      node_with_text(str) do |e| #Match each case
        case e['type']
        when 'pass'
          @v.msg(e['msg']+"[#{str}]")
        when 'warn'
          @v.msg(e['msg']+"[ (#{str}) for (#{pass}) ]")
        when 'error'
          @v.err(e['msg']+"[ (#{str}) for (#{pass}) ]")
        end
        node_with_id!(e['option']) if e['option']
        return raw
      end
    rescue IndexError
      raise $! if @verify_later[self]
      @v.msg "#{$!} and code [#{str}] into queue"
      @verify_later[self]=raw
      return raw
    end
    raise "No error desctiption for #{self['label']}"
  end

  def assign
    raw=cut_frame
    attr_with_key('field') do |fld|
      str=decode(raw) 
      @v.msg("[#{fld}] <- [#{str}]")
      @field[fld]=str
    end
    raw
  end

  def get_field
    str=String.new
    each_node do |e|
      case e.name
      when 'ccrange'
        e.checkcode(e.get_field)
      when 'verify'
        str << e.verify(e.cut_frame)
      when 'assign'
        str << e.assign
      end
    end
    return str
  end

  private
  def decode(code)
    attr_with_key('unpack') do |val|
      code=code.unpack(val).first
    end
    code.to_s
  end
  
end
