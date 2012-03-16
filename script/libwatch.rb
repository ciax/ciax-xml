#!/usr/bin/ruby
require 'libmsg'
require 'libexenum'
require 'librerange'
require 'libelapse'
require 'libmodlog'
require 'libiofile'

class Watch < ExHash
  attr_reader :period
  def initialize(adb,view)
    @v=Msg::Ver.new(self,12)
    @wdb=Msg.type?(adb,AppDb)[:watch] || return
    @period=(@wdb['period']||300).to_i
    @wst=@wdb[:stat]||[]
    @view=Msg.type?(view,Rview)
    ['active','stat','exec','block','int'].each{|i|
      self[i]||=[]
    }
  end

  def active?
    !self['active'].empty?
  end

  def block?(cmd)
    cmds=self['block']
    @v.msg{"BLOCKING:#{cmd}"} unless cmds.empty?
    cmds.include?(cmd)
  end

  def issue
    cmds=self['exec']
    return [] if cmds.empty?
    @v.msg{"ISSUED:#{cmds}"}
    sleep (@wdb['interval']||1).to_i
    cmds
  end

  def interrupt
    cmds=self['int']
    @v.msg{"ISSUED:#{cmds}"} unless cmds.empty?
    cmds
  end

  def upd
    self['active'].clear
    hash={'int' =>[],'exec' =>[],'block' =>[]}
    @wdb[:stat].size.times{|i|
      next unless check(i)
      self['active'] << i
      hash.each{|k,a|
        n=@wdb[k.to_sym][i]
        a << n if n && !a.include?(n)
      }
    }
    hash.each{|k,a|
      self[k]=a.flatten(1).uniq
    }
    @v.msg{"Updated"}
    self
  end

  private
  def check(i)
    return true unless @wdb[:stat][i]
    @v.msg{"Check: <#{@wdb[:label][i]}>"}
    n=@wdb[:stat][i]
    m=(self['stat'][i]||=[])
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
  require "libwatchprt"

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
  wprt=WatchPrt.new(adb,view)
  # For on change
  view.set(hash)
  watch.upd
  # Print Wdb
  puts wprt
end
