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
      e.verify_str(ele)
    end
    return @field
  end

  protected
  def cut_frame(len)
    warn "Too short (#{@frame.size-len})" if @frame.size < len
    return @frame.slice!(0,len)
  end

  def verify_str(raw)
    @prefix="Verify:"
    str=tr_text(raw)
    begin
      pass=text_with_attr('type','pass')
      node_with_text(str) do |e| #Match each case
        case e['type']
        when 'pass'
          e.msg("[#{str}]")
        when 'warn'
          e.msg("[ (#{str}) for (#{pass}) ]")
        when 'error'
          e.err("[ (#{str}) for (#{pass}) ]")
        end
        select_id(e['option']) if e['option']
        return
      end
    rescue
      raise $! if @verify_later[self]
      msg "#{$!} and code [#{str}] into queue"
      @verify_later[self]=raw
      return
    end
    raise "No error desctiption for #{self['label']}"
  end

  def assign_str(raw)
    @prefix="Assign:"
    fld=@doc.attributes['field']
    str=tr_text(raw) 
    msg("[#{fld}] <- [#{str}]")
    {fld => str}
  end

  def get_field
    str=String.new
    each do |e|
      len=e['length'].to_i
      case e.name
      when 'ccrange'
        str << ccstr=e.get_field
        @var.update(e.calc_cc(ccstr))
      when 'verify'
        str << ele=e.cut_frame(len)
        e.verify_str(ele)
      when 'assign'
        str << ele=e.cut_frame(len)
        @field.update(e.assign_str(ele))
      end
    end
    return str
  end

end
