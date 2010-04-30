#!/usr/bin/ruby
require "libmoddev"
require "libxmldb"
require "libmodfile"

class DevStat < XmlDb
  include ModDev
  include ModFile

  attr_reader :field
  def initialize(doc)
    super(doc,'//rspframe')
    @dev=@property['id']
    begin
      @field=load_stat(@dev)
    rescue
      @field={'device'=>@dev}
    end
    @verify_later=Hash.new
  end

  def devstat(str)
    err "No String" unless str
    @frame=str
    get_field
    @verify_later.each do |e,ele|
      e.verify(ele)
    end
    save_stat(@dev,@field)
    return @field
  end
  
  def node_with_id!(id)
    if id
      return self if super(id)
      return self if super('default')
      msg("Send Only")
    end
    nil
  end

  protected
  def cut_frame
    attr_with_key('length') do |l|
      len=l.to_i
      warn "Too short (#{@frame.size-len})" if @frame.size < len
      return @frame.slice!(0,len)
    end
  end

  def verify(raw)
    err "No input file" unless raw
    str=decode(raw)
    begin
      pass=node_with_attr('type','pass').text
      node_with_text(str) do |e| #Match each case
        case e['type']
        when 'pass'
          msg(e['msg']+"[#{str}]")
        when 'warn'
          msg(e['msg']+"[ (#{str}) for (#{pass}) ]")
        when 'error'
          err(e['msg']+"[ (#{str}) for (#{pass}) ]")
        end
        node_with_id!(e['option']) if e['option']
        return raw
      end
    rescue IndexError
      err $! if @verify_later[self]
      msg "#{$!} and code [#{str}] into queue"
      @verify_later[self]=raw
      return raw
    end
    err "No error desctiption for #{self['label']}"
  end

  def assign
    raw=cut_frame
    attr_with_key('field') do |fld|
      str=decode(raw) 
      msg("[#{fld}] <- [#{str}]")
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


