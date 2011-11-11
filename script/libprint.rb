#!/usr/bin/ruby
require 'librview'
class Print
  CM=Hash.new('2').update({'alarm' =>'1','warn' =>'3','hide' =>'0'})
  def initialize(adb,view)
    @sdb=Msg.type?(adb,AppDb)[:status]
    @view=Msg.type?(view,Rview)
    ['stat','class','msg'].each{|key|
      view[key]||={}
    }
  end

  def to_s
    get_group.join("\n")
  end

  private
  def get_group
    line=[]
    @sdb[:group].each{|k,v|
      cap=@sdb[:caption][k] || next
      line << " ***"+color(2,cap)+"***" unless cap.empty?
      col=@sdb[:column][k]||1
      v.each_slice(col.to_i){|ids|
        line << "  "+get_element(ids)
      }
    }
    line
  end

  def get_element(ids)
    ids.map{|id|
      prt(id,@view.stat(id))
    }.join(" ")
  end

  def prt(id,val)
    str='['
    str << color(6,@sdb[:label][id] || id.upcase)
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
  require "libinsdb"
  abort "Usage: #{$0} [view_file]" if STDIN.tty? && ARGV.size < 1
  view=Rview.new.load
  adb=InsDb.new(view['id']).cover_app
  puts Print.new(adb,view)
end
