#!/usr/bin/ruby
class Print < Array
  CM=Hash.new('2').update({'alarm' =>'1','warn' =>'3','hide' =>'0'})
  def initialize(view)
    @view=view
    @group = @view['group'] || @view['list'].keys
    get_group
  end

  def upd
    @view.upd
    clear
    get_group
  end

  private
  def get_group
    @group.each{|g|
      unless Array === g[0]
        id,*g=g
        cap=@view['label'][id] || next
        push "***"+color(2,cap)+"***"
      end
      g.each{|a|
        get_element(a)
      }
    }
    self
  end

  def get_element(ids,col=6)
    da=[]
    ids.each{|id|
      next unless @view['list'].key?(id)
      item=@view['list'][id]
      label=@view['label'][id] || id.upcase
      da << prt(item,label)
    }
    while da.size > 0
      push da.shift(col).join(" ")
    end
    self
  end

  def prt(item,label)
    str='['
    str << color(6,label)
    str << ':'
    msg=item['msg']
    c=CM[item['class']]
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
