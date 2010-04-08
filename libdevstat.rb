#!/usr/bin/ruby
require "libdev"
TopNode='//rspframe'
class DevStat < Dev
  def initialize(dev,cmd)
    super(dev,cmd)
    @field={'device'=>dev}
    @vq=Hash.new
  end
  def cutFrame
    len=a['length'].to_i
    warn "Too short (#{@frame.size-len})" if @frame.size < len
    return @frame.slice!(0,len)
  end
  def verify(code)
    str=trText(code)
    pass=String.new
    each do |d| #Match each case
      a=d.a
      begin
        text=d.getText(@var)
      rescue
        warn $! if ENV['VER']
        raise $! if @vq[self]
        @vq[self]=code
        return
      end
      pass=text if a['type'] == 'pass'
      if  text == str or text == nil
        case a['type']
        when 'pass'
          warn a['msg'] if ENV['VER']
        when 'warn'
          warn a['msg'] + "[ (#{str}) for (#{pass}) ]"
        when 'error'
          raise a['msg'] + "[ (#{str}) for (#{pass}) ]"
        end
#        @doc=selOpt('//rspframe',a['option']) if a['option']
        return
      end
    end
    raise "No error desctiption for #{e.attributes['label']}"
  end

  def putStr
    str=String.new
    each do |c|
      case c.name
      when 'ccrange'
        ccstr=c.putStr
        @var.update(c.calCc(ccstr))
        str << ccstr
      when 'verify'
        str << ele=c.cutFrame
        c.verify(ele)
      when 'assign'
        str << ele=c.cutFrame
        fld=c.a['field']
        data=c.trText(ele)
        @field[fld]=data
        warn "Assign #{fld} [#{data}]" if ENV['VER']
      end
    end
    return str
  end
  def rspfrm
    @frame=yield
    putStr
    @vq.each do |e,ele|
      e.verify(ele)
    end
    return @field
  end
end
