#!/usr/bin/ruby
require "libsymtbl"
require "libcircular"
class Print
  def initialize
    @c=Circular.new(4)
  end

  def print(stat,ver=nil)
    a=[]
    line=[]
    plabel=[]
    ptimes=0
    stat.each {|id,item|
      next unless item.class == Hash
      item['label']=id.upcase unless item['label']
      clabel=item['label'].split(/[ :]/)
      if clabel.first == plabel.first || clabel.last == plabel.last
        @c.next
      else
        @c.reset
      end
      if @c.times != ptimes
        a << line.join(' ') if line.size > 0
        line=[]
        ptimes=@c.times
      end
      plabel=clabel
      case item['class']
      when 'alarm'
        line << prt(item,'1')
      when 'warn'
        line << prt(item,'3')
      when 'normal'
        line << prt(item,'2')
      when 'hide'
        line << prt(item,'2') if ver
      else
        line << prt(item,'2')
      end
    }
    a << line.join(' ') if line.size > 0
    a.join("\n")+"\n"
  end

  private
  def color(c,msg)
    "\e[1;3#{c}m#{msg}\e[0m"
  end
  
  def prt(item,c)
    str='['
    title=item['label'] || item['title']
    str << color(6,title)
    str << ':'
    if item['msg'] && item['val']
      str << color(c,item['val']+'('+item['msg']+')')
    elsif item['msg']
      str << color(c,item['msg'])
    elsif item['val']
      str << color(c,item['val'])
    end
    str << "]"
  end

  def concat(ary)
    line=ary.compact.join(" ")
  end
end
