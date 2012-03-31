#!/usr/bin/ruby
require 'libview'
class ViewPrt
  CM=Hash.new(2).update({'active'=>5,'alarm' =>1,'warn' =>3,'hide' =>0})
  def initialize(view)
    @view=Msg.type?(view,View)
  end

  def to_s
    get_group.join("\n")
  end

  private
  def get_group
    lines=[]
    @view.each{|k,v|
      cap=v['caption']
      lines << " ***"+color(2,cap)+"***" unless cap.empty?
      v['lines'].each{|ele|
        lines << "  "+get_element(ele)
      }
    }
    lines
  end

  def get_element(ele)
    line=[]
    ele.each{|id,val|
      str='['
      str << color(6,val['label'] || id.upcase)
      str << ':'
      msg=val['msg']||val['val']
      c=CM[val['class']]
      str << color(c,msg)
      str << "]"
      line << str
    }
    line.join(" ")
  end

  def color(c,msg)
    "\e[1;3#{c}m#{msg}\e[0m"
  end
end

if __FILE__ == $0
  require "libinsdb"
  Msg.usage("[stat_file]") if STDIN.tty? && ARGV.size < 1
  stat=Stat.new.load
  adb=InsDb.new(stat['id']).cover_app
  view=View.new(adb,stat)
  puts ViewPrt.new(view)
end
