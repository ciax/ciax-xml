#!/usr/bin/ruby
require "libdev"
TopNode='//rspframe'
class DevStat < Dev
  def initialize(dev,cmd)
    super(dev,cmd)
    @field={'device'=>dev}
    @vq=Hash.new
  end

  def cut_frame(len)
    warn "Too short (#{@frame.size-len})" if @frame.size < len
    return @frame.slice!(0,len)
  end

  def verify_str(raw)
    str=tr_text(raw)
    pass=String.new
    each do |d| #Match each case
      begin
        text=d.get_text(@var)
      rescue
        raise $! if @vq[self]
        warn "#{$!} and code [#{str}] into queue" if ENV['VER']
        @vq[self]=raw
        return
      end
      pass=text if d['type'] == 'pass'
      if  text == str or text == nil
        case d['type']
        when 'pass'
          warn d['msg'] if ENV['VER']
        when 'warn'
          warn d['msg'] + "[ (#{str}) for (#{pass}) ]"
        when 'error'
          raise d['msg'] + "[ (#{str}) for (#{pass}) ]"
        end
        select_id(d['option']) if d['option']
        return
      end
    end
    raise "No error desctiption for #{d['label']}"
  end

  def assign_str(raw)
    fld=@doc.attributes['field']
    str=tr_text(raw)
    warn "Assign #{fld} [#{str}]" if ENV['VER']
    {fld => str}
  end

  def get_field
    str=String.new
    each do |c|
      len=c['length'].to_i
      case c.name
      when 'ccrange'
        ccstr=c.get_field
        @var.update(c.calc_cc(ccstr))
        str << ccstr
      when 'verify'
        str << ele=c.cut_frame(len)
        c.verify_str(ele)
      when 'assign'
        str << ele=c.cut_frame(len)
        @field.update(c.assign_str(ele))
      end
    end
    return str
  end

  def rspfrm
    @frame=yield
    get_field
    @vq.each do |e,ele|
      e.verify_str(ele)
    end
    return @field
  end
end







