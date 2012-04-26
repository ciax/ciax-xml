#!/usr/bin/ruby
require 'libmsg'
require 'libiofile'
require 'librerange'

module Watch
  class Stat < ExHash
    def initialize
      super
      self['type']='watch'
      ['exec','block','int'].each{|i|
        self[i]||=[]
      }
    end

    def active?
      ! self['active'].empty?
    end

    def act_list
      self['active']
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

  module Convert
    attr_reader :period,:interval
    def self.extended(obj)
      Msg.type?(obj,Stat)
    end

    def init(adb,val)
      @wdb=Msg.type?(adb,AppDb)[:watch] || {:stat => {}}
      @period=(@wdb['period']||300).to_i
      @interval=(@wdb['interval']||1).to_f/10
      @val=Msg.type?(val,Hash)
      # Pick usable val
      @list=@wdb[:stat].values.flatten(1).map{|h|
        h['var']
      }.uniq
      @list.unshift('time')
      self['val']=@crnt={}
      self['last']=@last=upd_crnt
      self['res']=@res={}
      self['active']=@act=[]
      self
    end

    def upd
      hash={'int' =>[],'exec' =>[],'block' =>[]}
      @act.clear
      @wdb[:stat].each{|i,v|
        next unless check(i)
        @act << i
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
        @res["#{i}:#{j}"]=res
        rary << res
      }
      rary.all?
    end
  end

  module View
    def self.extended(obj)
      Msg.type?(obj,Stat)
    end

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

  module Print
    def self.extended(obj)
      Msg.type?(obj,View)
    end

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
  wstat=Watch::Stat.new.extend(InFile).init(id).load
  unless opt['r']
    wstat.extend(Watch::View).init(adb)
    unless opt['v']
      wstat.extend(Watch::Print)
    end
  end
  if t=opt['t']
    val=ExHash.new.str_update(t)
    wstat.extend(Watch::Convert).init(adb,val).upd
  end
  puts wstat
end
