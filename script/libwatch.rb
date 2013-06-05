#!/usr/bin/ruby
require 'libmsg'
require 'libstatus'
require 'librerange'

module Watch
  class Var < Var
    # @ event_proc*
    attr_accessor :event_proc

    def initialize
      @ver_color=6
      super('watch')
      self['period']=300
      self['interval']=0.1
      self['astart']=nil
      self['alast']=0
      #For Array element
      ['active','exec','block','int'].each{|i| self[i]||=ExArray.new}
      #For Hash element
      ['crnt','last','res'].each{|i| self[i]||={}}
      @event_proc=proc{}
      self
    end

    def active?
      ! self['active'].empty?
    end

    def block?(cmd)
      cmds=self['block']
      verbose{["Watch","BLOCKING:#{cmd}"]} unless cmds.empty?
      cmds.include?(cmd[0]) && Msg.cmd_err("Blocking(#{cmd})")
    end

    def issue
      # block parm = cmd + priority(2)
      cmds=self['exec'].each{|cmd|
        @event_proc.call([cmd,2])
        verbose{["Watch","ISSUED:#{cmd}"]}
      }.dup
      self['exec'].clear
      cmds
    end

    def interrupt
      # block parm = cmd + priority(0)
      cmds=self['int'].each{|cmd|
        @event_proc.call([cmd,0])
        verbose{["Watch","ISSUED:#{cmd}"]}
      }.dup
      self['int'].clear
      cmds
    end

    def ext_upd(adb,stat)
      extend(Upd).ext_upd(adb,stat)
    end
  end

  module Upd
    include Var::Upd
    # @< (event_proc*)
    # @ wdb,val
    def self.extended(obj)
      Msg.type?(obj,Var)
    end

    def ext_upd(adb,stat)
      @wdb=Msg.type?(adb,App::Db)[:watch] || {:stat => {}}
      @stat=Msg.type?(stat,Status::Var)
      @val=@stat['val']
      @upd_proc=[]
      self['period']=@wdb['period'].to_i if @wdb.key?('period')
      self['interval']=@wdb['interval'].to_f/10 if @wdb.key?('interval')
      # Pick usable val
      @list=@wdb[:stat].values.flatten(1).map{|h|
        h['var']
      }.uniq
      @list.unshift('time')
      # @val(all) = self['crnt'](picked) > self['last']
      # upd() => self['last']<-self['crnt']
      #       => self['crnt']<-@val
      #       => check(self['crnt'] <> self['last']?)
      ['crnt','last','res'].each{|k| self[k]={}}
      upd_last
      @stat.upd_proc << proc{upd}
      self
    end

    # Stat no changed -> clear exec, no eval
    def upd
      self['exec'].clear
      return self if self['crnt']['time'] == @stat['time']
      upd_last
      hash={'int' =>[],'exec' =>[],'block' =>[]}
      noact=self['active'].empty?
      self['active'].clear
      @wdb[:stat].each{|i,v|
        next unless check(i)
        self['active'] << i
        hash.each{|k,a|
          n=@wdb[k.to_sym][i]
          a << n if n && !a.include?(n)
        }
      }
      lstart=self['astart']
      self['astart']=(noact & active?) ? UnixTime.now : nil
      self['alast']=UnixTime.now-lstart if lstart && !self['astart']
      hash.each{|k,a|
        self[k].replace a.flatten(1).uniq
      }
      verbose{["Watch","Updated(#{@stat['time']})"]}
      super
    end

    private
    def upd_last
      @list.each{|k|
        self['last'][k]=self['crnt'][k]
        self['crnt'][k]=@val[k]
      }
    end

    def check(i)
      return true unless @wdb[:stat][i]
      verbose{["Watch","Check: <#{@wdb[:label][i]}>"]}
      n=@wdb[:stat][i]
      rary=[]
      n.each_index{|j|
        k=n[j]['var']
        v=self['crnt'][k]
        case n[j]['type']
        when 'onchange'
          c=self['last'][k]
          res=(c != v)
          verbose{["Watch","  onChange(#{k}): [#{c}] vs <#{v}> =>#{res}"]}
        when 'pattern'
          c=n[j]['val']
          res=(Regexp.new(c) === v)
          verbose{["Watch","  Pattrn(#{k}): [#{c}] vs <#{v}> =>#{res}"]}
        when 'range'
          c=n[j]['val']
          f=cond[j]['val']="%.3f" % v.to_f
          res=(ReRange.new(c) == f)
          verbose{["Watch","  Range(#{k}): [#{c}] vs <#{f}>(#{v.class}) =>#{res}"]}
        end
        res=!res if /true|1/ === n[j]['inv']
        self['res']["#{i}:#{j}"]=res
        rary << res
      }
      rary.all?
    end
  end

  # For Client
  class View < ExHash
    def initialize(adb,watch)
      wdb=Msg.type?(adb,App::Db)[:watch] || {:stat => []}
      @watch=Msg.type?(watch,Var)
      ['exec','block','int','astart','alast'].each{|i|
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
          h['val']=@watch['crnt'][id]
          h['res']=@watch['res']["#{k}:#{i}"]
          h['cmp']=@watch['last'][id] if h['type'] == 'onchange'
        }
        v['active']=@watch['active'].include?(k)
      }
      super
    end

    def ext_prt
      extend Print
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
      }
      atime=Msg.elps_date(self['atime'])
      str << "  "+Msg.color("ActiveTime",2)+"\t: #{atime}\n"
      str << "  "+Msg.color("LastActive",2)+"\t: #{self['alast']}\n"
      str << "  "+Msg.color("Blocked",2)+"\t: #{self['block']}"
      str << "  "+Msg.color("Interrupt",2)+"\t: #{self['int']}"
      str << "  "+Msg.color("Issuing",2)+"\t: #{self['exec']}"
    end

    private
    def show_res(res,t=nil,f=nil)
      res ? Msg.color(t||res,2) : Msg.color(f||res,1)
    end
  end
end

if __FILE__ == $0
  require "liblocdb"

  list={}
  list['t']='test conditions[key=val,..]'
  Msg::GetOpts.new('rt:',list)
  id=ARGV.shift
  begin
    adb=Loc::Db.new.set(id)[:app]
  rescue InvalidID
    $opt.usage("(opt) [id]")
  end
  stat=Status::Var.new.ext_file(adb['site_id']).load
  watch=Watch::Var.new.ext_file(adb['site_id']).ext_upd(adb,stat).upd
  wview=Watch::View.new(adb,watch)
  unless $opt['r']
    wview.ext_prt
  end
  if t=$opt['t']
    stat.ext_save.str_update(t).upd.save
    watch.ext_save.upd.save
  end
  puts wview||watch
end
