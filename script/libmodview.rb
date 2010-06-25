#!/usr/bin/ruby
module ModView
  def view(stat)
    a=[]
    line=[]
    stat.each {|id,item|
      case item['hl']
      when 'alarm'
        line << prt(item,'1')
      when 'warn'
        line << prt(item,'3')
      when 'normal'
        line << prt(item,'2')
      when 'hide'
        line << prt(item,'2') if ENV['VER']
      else
        line << prt(item,'2')
      end
      next if item['trail']
      next unless line.size > 0
      a << line.join(' ')
      line=[]
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
    str << color(6,item['label'])
    str << ':'
    if item['type'] == 'ENUM'
      str << color(c,item['msg'])
    elsif item['msg']
      str << color(c,item['val']+'('+item['msg']+')')
    else
      str << color(c,item['val'])
    end
    str << "]"
  end

  def concat(ary)
    line=ary.compact.join(" ")
  end
end
