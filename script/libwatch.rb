#!/usr/bin/ruby
require 'libmsg'
require 'libiofile'
require 'librerange'

class Watch < Var
  attr_reader :active
  def initialize
    super('watch')
    ['active','exec','block','int'].each{|i|
      self[i]||=[]
    }
    @active=self['active']
  end

  def active?
    ! @active.empty?
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

module Watch::Conv
  attr_reader :period,:interval
  def self.extended(obj)
    Msg.type?(obj,Watch)
  end

  def init(adb,val)
    @wdb=Msg.type?(adb,App::Db)[:watch] || {:stat => {}}
    @val=Msg.type?(val,App::Rsp)
    @period=(@wdb['period']||300).to_i
    @interval=(@wdb['interval']||1).to_f/10
    # Pick usable val
    @list=@wdb[:stat].values.flatten(1).map{|h|
      h['var']
    }.uniq
    @list.unshift('time')
    self['val']=@crnt={}
    self['last']=@last=upd_crnt
    self['res']=@res={}
    self
  end

  def upd
    hash={'int' =>[],'exec' =>[],'block' =>[]}
    @active.clear
    @wdb[:stat].each{|i,v|
      next unless check(i)
      @active << i
      hash.each{|k,a|
        n=@wdb[k.to_sym][i]
        a << n if n && !a.include?(n)
      }
    }
    hash.each{|k,a|
      self[k]=a.flatten(1).uniq
    }
    if @crnt['time'] != @val['time']
      self['last']=@last=@crnt.dup
      upd_crnt
    end
    @v.msg{"Updated(#{@val['time']})"}
    self
  end

  private
  def upd_crnt
    @list.each{|k|
      @crnt[k]=@val[k]
    }
    @crnt
  end

  def check(i)
    return true unless @wdb[:stat][i]
    @v.msg{"Check: <#{@wdb[:label][i]}>"}
    n=@wdb[:stat][i]
    rary=[]
    n.each_index{|j|
      k=n[j]['var']
      v=@val[k]
      case n[j]['type']
      when 'onchange'
        c=@last[k]
        res=(c != v)
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
      @res["#{i}:#{j}"]=res
      rary << res
    }
    rary.all?
  end
end

class Watch::View < ExHash
  def initialize(adb,watch)
    wdb=Msg.type?(adb,App::Db)[:watch] || {:stat => []}
    @watch=Msg.type?(watch,Watch)
    ['exec','block','int'].each{|i|
      self[i]=@watch[i]
    }
    self['stat']={}
    wdb[:stat].each{|k,v|
      hash=(self['stat'][k]||={})
      hash['label']=wdb[:label][k]
      m=(hash['cond']||=[])
      v.size.times{|j|
        m[j]||={}
        m[j]['type']=v[j]['type']
        m[j]['var']=v[j]['var']
        m[j]['inv']=v[j]['inv']
        if v[j]['type'] != 'onchange'
          m[j]['cmp']=v[j]['val']
        end
      }
    }
    self
  end

  def to_s
    self['stat'].each{|k,v|
      v['cond'].each_index{|i|
        h=v['cond'][i]
        id=h['var']
        h['val']=@watch['val'][id]
        h['res']=@watch['res']["#{k}:#{i}"]
        h['cmp']=@watch['last'][id] if h['type'] == 'onchange'
      }
      v['active']=@watch['active'].include?(k)
    }
    super
  end
end

module Watch::Print
  def self.extended(obj)
    Msg.type?(obj,Watch::View)
  end

  def to_s
    return '' if self['stat'].empty?
    super
    str="  "+Msg.color("Conditions",2)+"\t:\n"
    self['stat'].each{|k,i|
      str << "    "+Msg.color(i['label'],6)+"\t: "
      str << show_res(i['active'])+"\n"
      i['cond'].each{|j|
        str << "      "+show_res(j['res'],'o','x')+' '
        str << Msg.color(j['var'],3)
        str << "  "
        str << "!" if j['inv']
        str << "(#{j['type']}: "
        if j['type'] == 'onchange'
          str << "#{j['cmp']} => #{j['val']}"
        else
          str << "/#{j['cmp']}/ =~ #{j['val']}"
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
  opt=ARGV.getopts('rvt:')
  id=ARGV.shift
  begin
    adb=InsDb.new(id).cover_app
  rescue SelectID
    Msg.usage("(-t key=val,..) (-rv) [id]",
              "-t:test conditions(key=val,..)",
              "-r:raw data","-v:view data")
  end
  wstat=Watch.new.extend(InFile).init(id).load
  unless opt['r']
    wview=Watch::View.new(adb,wstat)
    unless opt['v']
      wview.extend(Watch::Print)
    end
  end
  if t=opt['t']
    wstat.extend(Watch::Conv).init(adb)
    wstat.str_update(t).upd
  end
  puts wview||wstat
end
