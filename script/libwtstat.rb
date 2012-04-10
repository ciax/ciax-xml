#!/usr/bin/ruby
require 'libmsg'
require 'libiofile'
require 'librerange'
require 'libelapse'
require 'libmodlog'

class WtStat < IoFile
  def initialize(id=nil,host=nil)
    super('watch',id,host)
    ['stat','exec','block','int'].each{|i|
      self[i]||=[]
    }
  end

  def active?
    self['stat'].any?{|s|
      s['active']
    }
  end

  def act_list
    ary=[]
    self['stat'].each_with_index{|s,i|
      ary << i if s['active']
    }
    ary
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
    cmds
  end

  def interrupt
    cmds=self['int']
    @v.msg{"ISSUED:#{cmds}"} unless cmds.empty?
    cmds
  end
end

module WtStatW
  include Writable
  attr_reader :period
  def init(adb,val)
    @wdb=Msg.type?(adb,AppDb)[:watch] || return
    @period=(@wdb['period']||300).to_i
    @wst=@wdb[:stat]||[]
    @val=Msg.type?(val,Hash)
    self
  end

  def upd
    hash={'int' =>[],'exec' =>[],'block' =>[]}
    @wdb[:stat].each_index{|i|
      next unless check(i)
      hash.each{|k,a|
        n=@wdb[k.to_sym][i]
        a << n if n && !a.include?(n)
      }
    }
    hash.each{|k,a|
      self[k]=a.flatten(1).uniq
    }
    @v.msg{"Updated(#{@val['time']})"}
    self
  end

  private
  def check(i)
    return true unless @wdb[:stat][i]
    @v.msg{"Check: <#{@wdb[:label][i]}>"}
    n=@wdb[:stat][i]
    m=(self['stat'][i]||={'cond' => [],'active' => false})
    cond=m['cond']
    rary=[]
    n.each_index{|j|
      k=n[j]['var']
      v=(cond[j]||={})['val']=@val[k]
      case n[j]['type']
      when 'onchange'
        c=(cond[j]['last']||='')
        res=(c != v)
        c.replace(v)
        @v.msg{"  onChange(#{k}): [#{c}] vs <#{v}> =>#{res}"}
      when 'pattern'
        c=n[j]['val']
        res=(Regexp.new(c) === v)
        @v.msg{"  Pattrn(#{k}): [#{c}] vs <#{v}> =>#{res}"}
      when 'range'
        c=n[j]['val']
        f=cond[j]['val']="%.3f" % v.to_f
        res=(ReRange.new(c) == f)
        @v.msg{"  Range(#{k}): [#{c}] vs <#{f}>(#{v.class}) =>#{res}"}
      end
      res=!res if /true|1/ === n[j]['inv']
      rary << cond[j]['res']=res
    }
    m['active']=rary.all?
  end
end

if __FILE__ == $0
  require "libstat"
  require "libinsdb"
  id=ARGV.shift
  hash={}
  ARGV.each{|s|
    k,v=s.split("=")
    hash[k]=v
  }
  ARGV.clear
  begin
    adb=InsDb.new(id).cover_app
  rescue SelectID
    Msg.usage "[id] (test conditions (key=val)..)"
  end
  stat=Stat.new(id).load
  val=stat['val']
  watch=WtStat.new(id).extend(WtStatW).init(adb,val).upd.save
  # For on change
  val.update(hash)
  watch.upd
  # Print Wdb
  puts watch
end
