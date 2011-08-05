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
    pgr=0
    view['list'].each {|id,item|
      next unless item.class == Hash
      next unless item.key?('val')
      if item['grp'] != pgr
        line=flush(a,line)
        title=view['title'][item['grp']]
        a << "***"+color(2,title)+"***"
        @c.roundup
        pgr=item['grp']
      elsif item['row'] != prow
        @c.roundup
      end
      prow=item['row']
      if @c.next.col == 1
        line=flush(a,line)
      end
      item['label']=id.upcase unless item['label']
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
    flush(a,line)
    a.join("\n")+"\n"
  end

  private
  def flush(ary,line)
    ary << "  "+line.join(' ') if line.size > 0
    line=[]
  end

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
