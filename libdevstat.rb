#!/usr/bin/ruby
require "libdev"
TopNode='//rspframe'
class DevStat < Dev
  def initialize(dev,cmd)
    super(dev,cmd)
    @field={'device'=>dev}
    @verify_later=Hash.new
  end

  def rspfrm
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
    pass=String.new
    each do |e| #Match each case
      begin
        text=e.get_text(@var)
      rescue
        raise $! if @verify_later[self]
        warn "#{$!} and code [#{str}] into queue" if ENV['VER']
        @verify_later[self]=raw
        return
      end
      pass=text if e['type'] == 'pass'
      if  text == str or text == nil
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
    end
    raise "No error desctiption for #{e['label']}"
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
