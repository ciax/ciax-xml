#!/usr/bin/ruby
require 'libmsg'
require 'libexenum'

class WtView < ExHash
  def initialize(adb,stat)
    wdb=Msg.type?(adb,AppDb)[:watch] || {:stat => []}
    wst=Msg.type?(stat,Stat)['watch']
    self[:stat]=[]
    if wdb[:stat].size.times{|i|
      hash={}
      hash[:label]=wdb[:label][i]
      hash[:active]=wst['active'].include?(i)
      hash[:cond]=[]
      n=wdb[:stat][i]
      m=wst['stat'][i]
      n.size.times{|j|
        h={}
        h[:res]=m[j]['res']
        h[:var]=n[j]['var']
        h[:inv]=(/true|1/ === n[j]['inv'])
        h[:type]=n[j]['type']
        if n[j]['type'] == 'onchange'
          h[:cmp]=m[j]['last'].inspect
        else
          h[:cmp]=n[j]['val'].inspect
        end
        h[:val]=m[j]['val'].inspect
        hash[:cond] << h
      }
      self[:stat] << hash
    } > 0
    self[:block]=wst['block']
    self[:int]=wst['int']
    self[:exec]=wst['exec']
    end
  end
end

module WtViewPrt
  def to_s
    str=''
    unless self[:stat].each{|i|
      str << "  "+Msg.color(i[:label],6)+"\t: "
      str << show_res(i[:active])+"\n"
      i[:cond].each{|j|
        str << "    "+show_res(j[:res],'o','x')+' '
        str << Msg.color(j[:var],3)
        str << "  "
        str << "!" if j[:inv]
        str << "(#{j[:type]}"
        if j[:type] == 'onchange'
          str << "/last=#{j[:cmp]},now=#{j[:val]}"
        else
          str << "=#{j[:cmp]},actual=#{j[:val]}"
        end
        str << ")\n"
      }
    }.empty?
    str << "  "+Msg.color("Blocked",2)+"\t: #{self[:block]}\n"
    str << "  "+Msg.color("Interrupt",2)+"\t: #{self[:int]}\n"
    str << "  "+Msg.color("Issuing",2)+"\t: #{self[:exec]}\n"
    else
      ''
    end
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
  Msg.usage("(-r) [stat_file]") if STDIN.tty? && ARGV.size < 1
  stat=Stat.new.load
  adb=InsDb.new(stat['id']).cover_app
  wview=WtView.new(adb,stat)
  wview.extend(WtViewPrt) unless opt['r']
  puts wview
end
