#!/usr/bin/ruby
require "libdev"
TopNode='//rspframe'
class DevStat < Dev
  def initialize(dev,cmd)
    super(dev,cmd)
    @field={'device'=>dev}
    @vq=Hash.new
  end

  def cutoutFrame(len)
    warn "Too short (#{@frame.size-len})" if @frame.size < len
    return @frame.slice!(0,len)
  end

  def verifyStr(raw)
    str=trText(raw)
    pass=String.new
    each do |d| #Match each case
      begin
        text=d.getText(@var)
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

  def assignStr(raw)
    fld=@doc.attributes['field']
    str=trText(raw)
    warn "Assign #{fld} [#{str}]" if ENV['VER']
    {fld => str}
  end

  def putStr
    str=String.new
    each do |c|
      len=c['length'].to_i
      case c.name
      when 'ccrange'
        ccstr=c.putStr
        @var.update(c.calCc(ccstr))
        str << ccstr
      when 'verify'
        str << ele=c.cutoutFrame(len)
        c.verifyStr(ele)
      when 'assign'
        str << ele=c.cutoutFrame(len)
        @field.update(c.assignStr(ele))
      end
    end
    return str
  end

  def rspfrm
    @frame=yield
    putStr
    @vq.each do |e,ele|
      e.verifyStr(ele)
    end
    return @field
  end
end
