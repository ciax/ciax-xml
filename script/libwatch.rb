#!/usr/bin/ruby
require 'libmsg'
require 'libexenum'
require 'librerange'
require 'libelapse'
require 'libmodlog'
require 'libiofile'

module WatchPrt
  def to_s
    str=''
    if @wst.size.times{|i|
        res=self[:active].include?(i)
        str << "  "+Msg.color(@wdb[:label][i],6)+"\t: "
        str << show_res(res)+"\n"
        n=@wst[i]
        m=self[:stat][i]
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
      str << "  "+Msg.color("Last update",2)+"\t: #{@elapse}\n"
      str << "  "+Msg.color("Blocked",2)+"\t: #{self[:block]}\n"
      str << "  "+Msg.color("Interrupt",2)+"\t: #{self[:int]}\n"
      str << "  "+Msg.color("Issuing",2)+"\t: #{self[:exec]}\n"
    end
    str
  end
end

class Watch < IoFile
  attr_reader :period
  def initialize(adb,view)
    super('watch',adb['id'])
    @v=Msg::Ver.new(self,12)
    @wdb=Msg.type?(adb,AppDb)[:watch]
    @period=(@wdb['period']||300).to_i
    @wst=@wdb[:stat]||[]
    @view=Msg.type?(view,Rview)
    [:active,:stat,:exec,:block,:int].each{|i|
      self[i]||=[]
    }
    self['time']=Time.now.to_i
    self['ver']=adb['app_ver'].to_i
    @elapse=Elapse.new(self)
    view.updlist << proc{ yield upd.save.issue }
  end

  def active?
    !self[:active].empty?
  end

  def block?(cmd)
    cmds=self[:block]
    @v.msg{"BLOCKING:#{cmd}"} unless cmds.empty?
    cmds.include?(cmd)
  end

  def issue
    cmds=self[:exec]
    return [] if cmds.empty?
    @v.msg{"ISSUED:#{cmds}"}
    sleep (@wdb['interval']||1).to_i
    cmds
  end

  def interrupt
    cmds=self[:int]
    @v.msg{"ISSUED:#{cmds}"} unless cmds.empty?
    cmds
  end

  def upd
    self['time']=Time.now.to_i
    self[:active].clear
    hash={:int =>[],:exec =>[],:block =>[]}
    @wst.size.times{|i|
      next unless check(i)
      self[:active] << i
      hash.each{|k,a|
        n=@wdb[k][i]
        a << n if n && !a.include?(n)
      }
    }
    hash.each{|k,a|
      self[k]=a.flatten(1).uniq
    }
    self
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
      k=n[j]['var']
      v=(m[j]||={})['val']=@view.get(k).to_s
      case n[j]['type']
      when 'onchange'
        c=(m[j]['last']||='')
        res=(c != v)
        c.replace(v)
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
      res=!res if /true|1/ === n[j]['inv']
      rary << m[j]['res']=res
    }
    rary.all?
  end
end

if __FILE__ == $0
  require "librview"
  require "libinsdb"

  Msg.usage "(test conditions (key=val)..) < [file]" if STDIN.tty?
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
  puts watch.extend(WatchPrt)
end
