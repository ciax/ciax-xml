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
    [:active,:stat].each{|i|
      self[i]||=[]
    }
    self['time']=Time.now.to_i
    @elapse=Elapse.new(self)
  end

  def active?
    !self[:active].empty?
  end

  def block_pattern
    str=self[:active].map{|i|
      @wdb[:block][i]
    }.compact.join('|')
    @v.msg{"BLOCKING:#{str}"} unless str.empty?
    Regexp.new(str) unless str.empty?
  end

  def issue
    cmds=self[:active].map{|i|
      @wdb[:exec][i]
    }.compact.flatten(1).uniq
    @v.msg{"ISSUED:#{cmds}"} unless cmds.empty?
    cmds
  end

  def interrupt
    @view.last['int']=1
    upd
    @view.last['int']=nil
    issue
  end

  def upd
    self['time']=Time.now.to_f
    self[:active].clear
    @wst.size.times{|i|
      self[:active] << i if check(i)
    }
    @view.refresh
    self
  end

  def to_s
    str="  "+Msg.color("Last update",5)+":#{@elapse}\n"
    @wst.size.times{|i|
      res=self[:active].include?(i)
      str << "  "+Msg.color(@wdb[:label][i],6)+': '
      str << show_res(res)+"\n"
      if res
        if @wdb[:block][i]
          str << "    "+Msg.color("Block",3)
          str << ": /#{@wdb[:block][i]}/\n"
        end
        @wdb[:exec][i].each{|k|
          str << "    "+Msg.color("Issued",3)+": #{k}\n"
        }
      else
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
      end
    }
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
