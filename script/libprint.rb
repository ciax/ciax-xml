#!/usr/bin/ruby
class Print
  def initialize(view)
    @view=view
  end

  def to_s
    group = @view['group'] || @view['list'].keys
    arc_print(group)
  end

  private
  def arc_print(ary)
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
      line << fold(ids.map{|i|
        get_element(i)
      })
    else
      line << get_title(ids[0]) unless ids.empty?
      group.each{|a|
        line << arc_print(a)
      }
    end
    line.join("\n")
  end

  def get_title(title)
    "***"+color(2,title)+"***" if title
  end

  def get_element(id)
    return '' unless @view['list'].key?(id)
    item=@view['list'][id]
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

  def fold(ary,col=6)
    da=ary.dup
    row=[]
    while da.size > 0
      row << da.shift(col).join(" ")
    end
    row.join("\n")
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

  def color(c,msg)
    "\e[1;3#{c}m#{msg}\e[0m"
  end
end
