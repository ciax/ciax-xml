#!/usr/bin/ruby
require "libcircular"
class Print
  def initialize
    @c=Circular.new(5)
  end

  def print(view)
    group = view['group'] || view['list'].keys
    arc_print(group,view)
  end

  def arc_print(ary,view)
    ids=[]
    group=[]
    line=[]
    ary.each{|i|
      case i
      when Array
        group << i
      else
        ids << i
      end
    }
    if group.empty?
      line << ids.map{|i|
        get_element(view,i)
      }.join(" ")
    else
      line << "***"+color(2,ids[0])+"***" unless ids.empty?
      group.each{|a|
        line << arc_print(a,view)
      }
    end
    line.join("\n")
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

  def get_element(view,id)
    return '' unless view['list'].key?(id)
    item=view['list'][id]
    item['label']=id.upcase unless item['label']
    case item['class']
    when 'alarm'
      prt(item,'1')
    when 'warn'
      prt(item,'3')
    when 'normal'
      prt(item,'2')
    when 'hide'
      prt(item,'0')
    else
      prt(item,'2')
    end
  end
end
