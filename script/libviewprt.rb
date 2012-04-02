#!/usr/bin/ruby
require 'libview'
module ViewPrt
  CM=Hash.new(2).update({'active'=>5,'alarm' =>1,'warn' =>3,'hide' =>0})

  def to_s
    lines=[]
    each{|k,v|
      cap=v['caption']
      lines << " ***"+color(2,cap)+"***" unless cap.empty?
      lines+=v['lines'].map{|ele|
        "  "+ele.map{|id,val|
          c=CM[val['class']]
          '['+color(6,val['label'])+':'+color(c,val['msg'])+"]"
        }.join(' ')
      }
    }
    lines.join("\n")
  end

  private
  def color(c,msg)
    "\e[1;3#{c}m#{msg}\e[0m"
  end
end

if __FILE__ == $0
  require "libinsdb"
  Msg.usage("[stat_file]") if STDIN.tty? && ARGV.size < 1
  stat=Stat.new.load
  adb=InsDb.new(stat['id']).cover_app
  puts View.new(adb,stat).extend(ViewPrt)
end
