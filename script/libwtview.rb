#!/usr/bin/ruby
require 'libmsg'
require 'libwtstat'

module WtView
  def init(adb)
    wdb=Msg.type?(adb,AppDb)[:watch] || {:stat => []}
    wdb[:stat].size.times{|i|
      hash=(self['stat'][i]||={})
      hash['label']=wdb[:label][i]
      n=wdb[:stat][i]
      m=(hash['cond']||=[])
      n.size.times{|j|
        m[j]||={}
        m[j]['type']=n[j]['type']
        m[j]['var']=n[j]['var']
        if n[j]['type'] != 'onchange'
          m[j]['cmp']=n[j]['val'].inspect
        end
      }
    }
    self
  end
end

module WtViewPrt
  def to_s
    return '' if self['stat'].empty?
    str="  "+Msg.color("Conditions",2)+"\t:\n"
    self['stat'].each{|i|
      str << "    "+Msg.color(i['label'],6)+"\t: "
      str << show_res(i['active'])+"\n"
      i['cond'].each{|j|
        str << "      "+show_res(j['res'],'o','x')+' '
        str << Msg.color(j['var'],3)
        str << "  "
        str << "!" if j['inv']
        str << "(#{j['type']}"
        if j['type'] == 'onchange'
          str << "/last=#{j['last']},now=#{j['val']}"
        else
          str << "=#{j['cmp']},actual=#{j['val']}"
        end
        str << ")\n"
      }
    }.empty?
    str << "  "+Msg.color("Blocked",2)+"\t: #{self['block']}\n"
    str << "  "+Msg.color("Interrupt",2)+"\t: #{self['int']}\n"
    str << "  "+Msg.color("Issuing",2)+"\t: #{self['exec']}\n"
  end

  private
  def show_res(res,t=nil,f=nil)
    res ? Msg.color(t||res,2) : Msg.color(f||res,1)
  end
end

if __FILE__ == $0
  require "optparse"
  require "libinsdb"
  require "libstat"
  opt=ARGV.getopts('r')
  id=ARGV.shift
  begin
    adb=InsDb.new(id).cover_app
  rescue SelectID
    Msg.usage("(-r) [id]")
  end
  wstat=WtStat.new(id).load.extend(WtView).init(adb)
  wstat.extend(WtViewPrt) unless opt['r']
  puts wstat
end
