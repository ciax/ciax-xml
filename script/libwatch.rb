#!/usr/bin/ruby
require 'libmsg'
require 'libstatus'
require 'librerange'

module Watch
  class Var < Var
    extend Msg::Ver
    #@< (type*),(id*),(ver*),val*,(upd_proc*)
    #@ event_proc*
    attr_reader :event_proc

    def initialize
      Var.init_ver('Watch',6)
      super('watch')
      self['period']=300
      self['interval']=0.1
      #For Array element
      ['active','exec','block','int'].each{|i| self[i]||=[]}
      #For Hash element
      ['crnt','last','res'].each{|i| self[i]||={}}
      @event_proc=Update.new
      self
    end

    def active?
      ! self['active'].empty?
    end

    def block?(cmd)
      cmds=self['block']
      Var.msg{"BLOCKING:#{cmd}"} unless cmds.empty?
      cmds.include?(cmd[0]) && Msg.cmd_err("Blocking(#{cmd})")
    end

    def issue
      # block parm = cmd + priority(2)
      cmds=self['exec'].each{|cmd|
        @event_proc.exe([cmd,2])
        Var.msg{"ISSUED:#{cmd}"}
      }.dup
      self['exec'].clear
      cmds
    end

    def interrupt
      # block parm = cmd + priority(0)
      cmds=self['int'].each{|cmd|
        @event_proc.exe([cmd,0])
        Var.msg{"ISSUED:#{cmd}"}
      }.dup
      self['int'].clear
      cmds
    end

    def ext_conv(adb,stat)
      extend(Conv).init(adb,stat)
    end
  end

  module Conv
    #@<< type*,id*,ver*,val*,upd_proc*
    #@< (event_proc*)
    #@ wdb,list,crnt,res
    def self.extended(obj)
      Msg.type?(obj,Var)
    end

    def init(adb,stat)
      @wdb=Msg.type?(adb,App::Db)[:watch] || {:stat => {}}
      @val=Msg.type?(stat,Status::Var).val
      @last=stat.last
      self['period']=@wdb['period'].to_i if @wdb.key?('period')
      self['interval']=@wdb['interval'].to_f/10 if @wdb.key?('interval')
      # Pick usable val
      @list=@wdb[:stat].values.flatten(1).map{|h|
        h['var']
      }.uniq
      @list.unshift('time')
      # @val(all) = @crnt(picked) > @last
      # upd() => @last<-@crnt => @crnt<-@val => check(@crnt <> @last?)
      self['crnt']=@crnt={}
      self['last']=@last={}
      self['res']=@res={}
      upd_last
      self
    end

    # Stat no changed -> clear exec, no eval
    def upd
      self['exec'].clear
      return self if @crnt['time'] == @val['time']
      upd_last 
      hash={'int' =>[],'exec' =>[],'block' =>[]}
      self['active'].clear
      @wdb[:stat].each{|i,v|
        next unless check(i)
        self['active'] << i
        hash.each{|k,a|
          n=@wdb[k.to_sym][i]
          a << n if n && !a.include?(n)
        }
      }
      hash.each{|k,a|
        self[k].replace a.flatten(1).uniq
      }
      Var.msg{"Watch/Updated(#{@val['time']})"}
      self
    end

    private
    def upd_last
      @list.each{|k|
        @last[k]=@crnt[k]
        @crnt[k]=@val[k]
      }
    end

    def check(i)
      return true unless @wdb[:stat][i]
      Var.msg{"Check: <#{@wdb[:label][i]}>"}
      n=@wdb[:stat][i]
      rary=[]
      n.each_index{|j|
        k=n[j]['var']
        v=@crnt[k]
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

  # For Client
  class View < ExHash
    def initialize(adb,watch)
      wdb=Msg.type?(adb,App::Db)[:watch] || {:stat => []}
      @watch=Msg.type?(watch,Var)
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
          h['crnt']=@watch['crnt'][id]
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
  require "liblocdb"

  list={}
  list['t']='test conditions[key=val,..]'
  list['r']="raw data"
  list["v"]="view data"
  opt=Msg::GetOpts.new('rvt:',list)
  id=ARGV.shift
  begin
    adb=Loc::Db.new(id)[:app]
  rescue InvalidID
    opt.usage("(opt) [id]")
  end
  stat=Status::Var.new.ext_file(adb).load
  watch=Watch::Var.new.ext_file(adb).ext_conv(adb,stat).upd
  unless opt['r']
    wview=Watch::View.new(adb,watch)
    unless opt['v']
      wview.ext_prt
    end
  end
  if t=opt['t']
    stat.ext_save.str_update(t).upd.save
    watch.ext_save.upd.save
  end
  puts wview||watch
end
