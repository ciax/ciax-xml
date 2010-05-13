#!/usr/bin/ruby
require "libxmldev"
require "libiofile"

class DevStat < XmlDev

  attr_reader :field
  def initialize(doc)
    super(doc,'//rspframe')
    dev=@property['id']
    @f=IoFile.new(dev)
    begin
      @field=@f.load_stat
    rescue
      @field={'device'=>dev}
    end
    @verify_later=Hash.new
  end

  def devstat(str)
    @v.err "No String" unless str
    @var.clear
    @frame=str
    @f.save_frame("stat_#{@id}",str)
    get_field
    @verify_later.each do |e,ele|
      e.verify(ele)
    end
    @verify_later.clear
    @field['time']=Time.now.to_f.to_s
    @f.save_stat(@field)
  end
  
  def node_with_id!(id)
    raise "No id" unless id
    begin
      super(id)
    rescue
      begin
        super('default')
      rescue
        raise "Send Only"
      end
    end
    self
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
    @v.err "No input file" unless raw
    str=decode(raw)
    begin
      pass=node_with_attr('type','pass').text
      node_with_text(str) do |e| #Match each case
        case e['type']
        when 'pass'
          @v.msg(e['msg']+"[#{str}]",1)
        when 'warn'
          @v.msg(e['msg']+"[ (#{str}) for (#{pass}) ]",1)
        when 'error'
          @v.err(e['msg']+"[ (#{str}) for (#{pass}) ]")
        end
        node_with_id!(e['option']) if e['option']
        return raw
      end
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
    attr_with_key('field') do |fld|
      str=decode(raw) 
      @v.msg("[#{fld}] <- [#{str}]",1)
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


