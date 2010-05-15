#!/usr/bin/ruby
module ModView
  def view(stat)
    stat.each {|id,item|
      case item['hl']
      when 'alarm'
        prt(item,'1')
      when 'warn'
        prt(item,'3')
      when 'normal'
        prt(item,'2')
      when 'hide'
        prt(item,'2') if ENV['VER']
      else
        prt(item,'2')
      end
    }
  end

  private
  def color(c,msg)
    print "\e[1;3#{c}m#{msg}\e[0m"
  end
  
  def prt(item,c)
    print '['
    color(6,item['label'])
    print ':'
    if item['type'] == 'ENUM'
      color(c,item['msg'])
    elsif item['msg']
      color(c,item['val']+'('+item['msg']+')')
    else
      color(c,item['val'])
    end
    puts ']'
  end

end
