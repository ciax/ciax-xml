#!/usr/bin/ruby
module ModView
  def view(stat)
    str=''
    stat.each {|id,item|
      case item['hl']
      when 'alarm'
        str << prt(item,'1')
      when 'warn'
        str << prt(item,'3')
      when 'normal'
        str << prt(item,'2')
      when 'hide'
        str << prt(item,'2') if ENV['VER']
      else
        str << prt(item,'2')
      end
    }
    str
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
    str << "]\n"
  end

end
