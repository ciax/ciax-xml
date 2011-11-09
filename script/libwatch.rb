#!/usr/bin/ruby
require 'libmsg'
require 'libmodexh'
require 'librerange'
require 'libelapse'
require 'yaml'

class Watch < Hash
  include ModExh
  def initialize(adb,view)
    @v=Msg::Ver.new("watch",12)
    @wdb=Msg.type?(adb,AppDb)[:watch]
    @wst=@wdb[:stat]||[]
    @view=Msg.type?(view,Rview)
    [:active,:stat,:exec,:block,:int].each{|i|
      self[i]||=[]
    }
    self['time']=Time.now.to_i
    @elapse=Elapse.new(self)
  end

  def active?
    !self[:active].empty?
  end

  def block_pattern
    str=self[:block]
    @v.msg{"BLOCKING:#{str}"} unless str.empty?
    Regexp.new(str) unless str.empty?
  end

  def issue
    cmds=self[:exec]
    @v.msg{"ISSUED:#{cmds}"} unless cmds.empty?
    cmds
  end

  def interrupt
    cmds=self[:int]
    @v.msg{"ISSUED:#{cmds}"} unless cmds.empty?
    cmds
  end

  def upd
    self['time']=Time.now.to_f
    self[:active].clear
    exec=[]
    block=[]
    int=[]
    @wst.size.times{|i|
      next unless check(i)
      self[:active] << i
      n=@wdb[:int][i]
      int << n if n && !int.include?(n)
      n=@wdb[:exec][i]
      exec << n if n && !exec.include?(n)
      n=@wdb[:block][i]||next
      block << n.map{|cmd|
        cmd.join(' ')
      }.join('|')
    }
    self[:int]=int.flatten(1).uniq
    self[:exec]=exec.flatten(1).uniq
    self[:block]=block.join('|')
    @view.refresh
    self
  end

  def to_s
    str="  "+Msg.color("Last update",5)+":#{@elapse}\n"
    @wst.size.times{|i|
      res=self[:active].include?(i)
      str << "  "+Msg.color(@wdb[:label][i],6)+': '
      str << show_res(res)+"\n"
      n=@wst[i]
      m=self[:stat][i]
      n.size.times{|j|
        str << "    "+show_res(m[j]['res'],'o','x')+' '
        str << Msg.color(n[j]['ref'],3)
        str << " (#{n[j]['type']}/"
        if n[j]['type'] == 'onchange'
          str << "last=#{m[j]['last'].inspect},"
          str << "now=#{m[j]['val'].inspect}"
        else
          str << "expected=#{n[j]['val'].inspect},"
          str << "actual=#{m[j]['val'].inspect}"
        end
        str << ")\n"
      }
    }
    str << "  "+Msg.color("Block",5)+": /#{self[:block]}/\n"
    str << "  "+Msg.color("Interrupt",5)+": #{self[:int]}\n"
    str << "  "+Msg.color("Issuing",5)+": #{self[:exec]}\n"
    str
  end

  private
  def show_res(res,t=nil,f=nil)
    res ? Msg.color(t||res,2) : Msg.color(f||res,1)
  end

  def check(i)
    return true unless @wst[i]
    @v.msg{"Check: <#{@wdb[:label][i]}>"}
    n=@wst[i]
    m=(self[:stat][i]||=[])
    rary=[]
    n.size.times{|j|
      k=n[j]['ref']
      v=(m[j]||={})['val']=@view.stat(k)
      case n[j]['type']
      when 'onchange'
        c=m[j]['last']=@view.last[k]
        res=(c != v)
        @v.msg{"  onChange(#{k}): [#{c}] vs <#{v}> =>#{res}"}
      when 'pattern'
        c=n[j]['val']
        res=(Regexp.new(c) === v)
        @v.msg{"  Pattrn(#{k}): [#{c}] vs <#{v}> =>#{res}"}
      when 'range'
        c=n[j]['val']
        f=m[j]['val']="%.3f" % v.to_f
        res=(ReRange.new(c) == f)
        @v.msg{"  Range(#{k}): [#{c}] vs <#{f}>(#{v.class}) =>#{res}"}
      end
      rary << m[j]['res']=res
    }
    rary.all?
  end
end

if __FILE__ == $0
  require "librview"
  require "libinsdb"
  abort "Usage: #{$0} (test conditions (key=val)..) < [file]" if STDIN.tty?
  hash={}
  ARGV.each{|s|
    k,v=s.split("=")
    hash[k]=v
  }
  ARGV.clear
  view=Rview.new.load
  begin
    adb=InsDb.new(view['id']).cover_app
  rescue SelectID
    Msg.exit
  end
  watch=Watch.new(adb,view).upd
  # For on change
  view.set(hash)
  # Print Wdb
  puts Msg.view_struct(watch.upd)
  puts watch
end
