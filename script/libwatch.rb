#!/usr/bin/ruby
require 'libmsg'
require 'libstatus'
require 'librerange'

module Watch
  module Var
    extend Msg::Ver
    attr_reader :active,:period,:interval,:watch

    def self.extended(obj)
      init_ver('Watch',3)
      Msg.type?(obj,Status::Var).init
    end

    def init
      @watch=(self['watch']||={}).extend(ExEnum)
      ['active','exec','block','int'].each{|i|
        @watch[i]||=[]
      }
      @active=@watch['active']
      @period=300
      @interval=0.1
    end

    def active?
      ! @active.empty?
    end

    def block?(cmd)
      cmds=@watch['block']
      Var.msg{"BLOCKING:#{cmd}"} unless cmds.empty?
      cmds.include?(cmd)
    end

    def issue
      cmds=@watch['exec']
      return [] if cmds.empty?
      Var.msg{"ISSUED:#{cmds}"}
      cmds
    end

    def interrupt
      cmds=@watch['int']
      Var.msg{"ISSUED:#{cmds}"} unless cmds.empty?
      cmds
    end
  end

  module Conv
    def self.extended(obj)
      Msg.type?(obj,Var)
    end

    def init(adb)
      @wdb=Msg.type?(adb,App::Db)[:watch] || {:stat => {}}
      @period=@wdb['period'].to_i if @wdb.key?('period')
      @interval=@wdb['interval'].to_f/10 if @wdb.key?('interval')
      # Pick usable val
      @list=@wdb[:stat].values.flatten(1).map{|h|
        h['var']
      }.uniq
      @list.unshift('time')
      @watch['val']=@crnt={}
      @watch['last']=@last=upd_crnt
      @watch['res']=@res={}
      self
    end

    def upd
      super
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
        @watch[k]=a.flatten(1).uniq
      }
      if @crnt['time'] != @val['time']
        @watch['last']=@last=@crnt.dup
        upd_crnt
      end
      Var.msg{"Watch/Updated(#{@val['time']})"}
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
      Var.msg{"Check: <#{@wdb[:label][i]}>"}
      n=@wdb[:stat][i]
      rary=[]
      n.each_index{|j|
        k=n[j]['var']
        v=@val[k]
        case n[j]['type']
        when 'onchange'
          c=@last[k]
          res=(c != v)
          Var.msg{"  onChange(#{k}): [#{c}] vs <#{v}> =>#{res}"}
        when 'pattern'
          c=n[j]['val']
          res=(Regexp.new(c) === v)
          Var.msg{"  Pattrn(#{k}): [#{c}] vs <#{v}> =>#{res}"}
        when 'range'
          c=n[j]['val']
          f=cond[j]['val']="%.3f" % v.to_f
          res=(ReRange.new(c) == f)
          Var.msg{"  Range(#{k}): [#{c}] vs <#{f}>(#{v.class}) =>#{res}"}
        end
        res=!res if /true|1/ === n[j]['inv']
        @res["#{i}:#{j}"]=res
        rary << res
      }
      rary.all?
    end
  end

  class View < ExHash
    def initialize(adb,stat)
      wdb=Msg.type?(adb,App::Db)[:watch] || {:stat => []}
      @watch=Msg.type?(stat,Var)['watch']
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

  module Print
    def self.extended(obj)
      Msg.type?(obj,View)
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
end

if __FILE__ == $0
  require "optparse"
  require "libinsdb"

  opt=ARGV.getopts('rvt:')
  id=ARGV.shift
  begin
    adb=Ins::Db.new(id).cover_app
  rescue SelectID
    Msg.usage("(-t key=val,..) (-rv) [id]",
              "-t:test conditions(key=val,..)",
              "-r:raw data","-v:view data")
  end
  stat=Status::Var.new.ext_save(id).load
  stat.extend(Watch::Var)
  unless opt['r']
    wview=Watch::View.new(adb,stat)
    unless opt['v']
      wview.extend(Watch::Print)
    end
  end
  if t=opt['t']
    stat.extend(Watch::Conv).init(adb)
    stat.str_update(t).upd.save
  end
  puts wview||stat['watch']
end
