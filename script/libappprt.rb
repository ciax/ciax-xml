#!/usr/bin/ruby
require 'libstat'
class AppPrt
  CM=Hash.new(2).update({'active'=>5,'alarm' =>1,'warn' =>3,'hide' =>0})
  def initialize(adb,stat)
    @sdb=Msg.type?(adb,AppDb)[:status]
    @stat=Msg.type?(stat,Stat)
    ['val','class','msg'].each{|key|
      stat[key]||={}
    }
    @elapse=Elapse.new(stat['val'])
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
      case id
      when 'elapse'
        str=@elapse
      else
        str=@stat['val'][id]
      end
      prt(id,str)
    }.join(" ")
  end

  def prt(id,val)
    str='['
    str << color(6,@sdb[:label][id] || id.upcase)
    str << ':'
    msg=@stat['msg'][id]
    c=CM[@stat['class'][id]]
    str << color(c,msg||val)
    str << "]"
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
  puts AppPrt.new(adb,stat)
end
