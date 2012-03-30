#!/usr/bin/ruby
require 'libmsg'

class WatchPrt
  def initialize(adb,view)
    @wdb=Msg.type?(adb,AppDb)[:watch]
    @wst=Msg.type?(view,Rview)['watch']
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
  require "librview"
  Msg.usage("[view_file]") if STDIN.tty? && ARGV.size < 1
  view=Rview.new.load
  adb=InsDb.new(view['id']).cover_app
  puts WatchPrt.new(adb,view)
end
