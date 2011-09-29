#!/usr/bin/ruby
require 'libelapse'
class Print < Array
  CM=Hash.new('2').update({'alarm' =>'1','warn' =>'3','hide' =>'0'})
  def initialize(db,view)
    @view=view
    view['stat']||= {}
    view['symbol']||= {}
    @elapse=Elapse.new(view['stat'])
    @group=db[:group] || [[db[:select].keys]]
    @label=db[:label] || {}
  end

  def upd
    clear
    get_group
    self
  end

  def to_s
    join("\n")
  end

  private
  def get_group
    @group.each{|g|
      arys,ids = g.partition{|e| Array === e}
      unless ids.empty?
        cap=@label[ids.first] || next
        push " ***"+color(2,cap)+"***"
      end
      arys.each{|a|
        get_element(a)
      }
    }
    self
  end

  def get_element(ids,col=6)
    da=[]
    ids.each{|id|
      case id
      when 'elapse'
        val=@elapse.to_s
      else
        val=@view['stat'][id]
      end
      symbol=@view['symbol'][id]||{}
      label=@label[id] || id.upcase
      da << prt(symbol,label,val)
    }
    da.each_slice(col){|a|
      push "  "+a.join(" ")
    }
    self
  end

  def prt(symbol,label,val)
    str='['
    str << color(6,label)
    str << ':'
    msg=symbol['msg']
    c=CM[symbol['class']]
    case v=symbol['type']
    when 'num'
      str << color(c,"#{val}(#{msg})")
    else
      str << color(c,msg||val)
    end
    str << "]"
  end

  def color(c,msg)
    "\e[1;3#{c}m#{msg}\e[0m"
  end
end

if __FILE__ == $0
  require "json"
  require "libinsdb"
  abort "Usage: #{$0} [status_file]" if STDIN.tty? && ARGV.size < 1
  while gets
    view=JSON.load($_)
    db=InsDb.new(view['id']).cover_app
    puts Print.new(db[:status],view).upd
  end
end
