#!/usr/bin/ruby
require 'libelapse'
class Print
  CM=Hash.new('2').update({'alarm' =>'1','warn' =>'3','hide' =>'0'})
  def initialize(db,view)
    @view=Msg.type?(view,ExHash)
    ['stat','class','msg'].each{|key|
      view[key]||={}
    }
    @elapse=Elapse.new(view['stat'])
    @group=db[:group] || [[db[:select].keys]]
    @label=db[:label] || {}
    @line=[]
  end

  def to_s
    @line.clear
    get_group
    @line.join("\n")
  end

  private
  def get_group
    @group.each{|g|
      arys,ids = g.partition{|e| Array === e}
      unless ids.empty?
        cap=@label[ids.first] || next
        @line << " ***"+color(2,cap)+"***"
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
      da << prt(id,val)
    }
    da.each_slice(col){|a|
      @line << "  "+a.join(" ")
    }
    self
  end

  def prt(id,val)
    str='['
    str << color(6,@label[id] || id.upcase)
    str << ':'
    msg=@view['msg'][id]
    c=CM[@view['class'][id]]
    str << color(c,msg||val)
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
    puts Print.new(db[:status],view)
  end
end
