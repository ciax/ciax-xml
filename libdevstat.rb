#!/usr/bin/ruby
require "libdev"
TopNode='//rspframe'
class DevStat < Dev
  def initialize(dev)
    super(dev)
    @field={'device'=>@doc.type}
  end
  def cutFrame(e)
    len=e.attr['length'].to_i
    warn "Too short (#{@frame.size-len})" if @frame.size < len
    return @frame.slice!(0,len)
  end
  def verify(e,code)
    str=trText(e,code)
    pass=String.new
    e.each do |d| #Match each case
      a=d.attr
      begin
        text=@var.getText(d)
      rescue
        warn $! if ENV['VER']
        raise $! if @vq[e]
        @vq[e]=code
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

  def putStr(e)
    str=String.new
    e.each do |c|
      a=c.attr
      case c.name
      when 'ccrange'
        str << @var.calCc(c,putStr(c))
      when 'select'
        str << putStr(@doc.sel)
      when 'verify'
        str << ele=cutFrame(c)
        verify(c,ele)
      when 'assign'
        str << ele=cutFrame(c)
        fld=a['field']
        data=trText(c,ele)
        @field[fld]=data
        warn "Assign #{fld} [#{data}]" if ENV['VER']
      end
    end
    return str
  end
  def rspfrm
    @frame=yield
    @vq=Hash.new
    putStr(@doc)
    @vq.each do |e,ele|
      verify(e,ele)
    end
    return @field
  end

end
