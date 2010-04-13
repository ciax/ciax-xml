#!/usr/bin/ruby
require "libdev"
TopNode='//rspframe'
class DevStat < Dev
  def initialize(dev,cmd)
    super(dev,cmd)
    @field={'device'=>dev}
    @verify_later=Hash.new
  end

  def devstat
    @frame=yield
    get_field
    @verify_later.each do |e,ele|
      e.verify(ele)
    end
    return @field
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
        select_id(e['option']) if e['option']
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
    attr?('field') do |fld|
      str=decode(raw) 
      @v.msg("[#{fld}] <- [#{str}]")
      @field[fld]=str
    end
    raw
  end

  def get_field
    str=String.new
    each do |e|
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
    attr?('unpack') do |val|
      code=code.unpack(val).first
    end
    code.to_s
  end
  
end


