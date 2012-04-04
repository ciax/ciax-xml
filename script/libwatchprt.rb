#!/usr/bin/ruby
require 'libmsg'

class WatchPrt
  def initialize(adb,stat)
    @wdb=Msg.type?(adb,AppDb)[:watch] || {:stat => []}
    @wst=Msg.type?(stat,Stat)['watch']
  end

  def to_s
    str=''
    if @wdb[:stat].size.times{|i|
        res=@wst['active'].include?(i)
        str << "  "+Msg.color(@wdb[:label][i],6)+"\t: "
        str << show_res(res)+"\n"
        n=@wdb[:stat][i]
        m=@wst['stat'][i]
        n.size.times{|j|
          str << "    "+show_res(m[j]['res'],'o','x')+' '
          str << Msg.color(n[j]['var'],3)
          str << "  "
          str << "!" if /true|1/ === n[j]['inv']
          str << "(#{n[j]['type']}"
          if n[j]['type'] == 'onchange'
            str << "/last=#{m[j]['last'].inspect},"
            str << "now=#{m[j]['val'].inspect}"
          else
            str << "=#{n[j]['val'].inspect},"
            str << "actual=#{m[j]['val'].inspect}"
          end
          str << ")\n"
        }
      } > 0
      str << "  "+Msg.color("Blocked",2)+"\t: #{@wst['block']}\n"
      str << "  "+Msg.color("Interrupt",2)+"\t: #{@wst['int']}\n"
      str << "  "+Msg.color("Issuing",2)+"\t: #{@wst['exec']}\n"
    end
    str
  end

  private
  def show_res(res,t=nil,f=nil)
    res ? Msg.color(t||res,2) : Msg.color(f||res,1)
  end
end

if __FILE__ == $0
  require "libinsdb"
  require "libstat"
  Msg.usage("[stat_file]") if STDIN.tty? && ARGV.size < 1
  stat=Stat.new.load
  adb=InsDb.new(stat['id']).cover_app
  puts WatchPrt.new(adb,stat)
end
