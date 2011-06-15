#!/usr/bin/ruby
require "libcircular"
class Print
  def initialize
    @c=Circular.new(5)
  end

  def print(view,ver=nil)
    a=[]
    line=[]
    prow=0
    view['list'].each {|item|
      next unless item.class == Hash
      next unless item.key?('val')
      id=item['id']
      item['label']=id.upcase unless item['label']
      @c.reset if item['row'] != prow
      if @c.next.col == 1
        a << line.join(' ') if line.size > 0
        line=[]
      end
      prow=item['row']
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
    msg=item['msg']
    case v=item['val']
    when Numeric
      str << color(c,"#{v}(#{msg})")
    else
      str << color(c,msg||v)
    end
    str << "]"
  end
end
