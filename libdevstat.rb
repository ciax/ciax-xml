#!/usr/bin/ruby
require "libdev"
TopNode='//rspframe'
class DevStat < Dev
  def initialize(dev)
    super(dev)
    @field={'device'=>@doc.type}
  end
  def cutRsp(e)
    len=e.attributes['length'].to_i
    warn "Too short (#{@res.size-len})" if @res.size < len
    return @res.slice!(0,len)
  end
  def verify(e,code)
    str=trText(e,code)
    pass=String.new
    e.elements.each do |d| #Match each case
      a=d.attributes
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
    e.elements.each do |c|
      a=c.attributes
      case c.name
      when 'ccrange'
        str << @var.calCc(c,putStr(c))
      when 'select'
        str << putStr(@doc.sel)
      when 'verify'
        str << ele=cutRsp(c)
        verify(c,ele)
      when 'assign'
        str << ele=cutRsp(c)
        fld=a['field']
        data=trText(c,ele)
        @field[fld]=data
        warn "Assign #{fld} [#{data}]" if ENV['VER']
      end
    end
    return str
  end
  def rspfrm
    @res=yield
    @vq=Hash.new
    putStr(@doc.top_node)
    @vq.each do |e,ele|
      verify(e,ele)
    end
    return @field
  end

end
