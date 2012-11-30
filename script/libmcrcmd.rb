#!/usr/bin/ruby
require "libapplist"
require "libcmdext"
require "libmcrprt"

module Mcr
  module Cmd
    extend Msg::Ver
    # @<< (index),(id*),(par*),cmd*,(def_proc*)
    # @< select*
    # @ aint,opt
    def self.extended(obj)
      init_ver('McrCmd',9)
      Msg.type?(obj,Command::ExtItem)
    end

    def ext_mcrcmd(aint,logs,opt={})
      @aint=Msg.type?(aint,App::List)
      @opt=Msg.type?(opt,Hash)
      @logs=Msg.type?(logs,Array)
      self
    end

    def exe
      @logs << (rec={:time => Time.new.to_f})
      rec[:thread]=Thread.new(rec){|record|
        current={'type'=>'mcr','mcr'=>@cmd,'label'=>self[:label]}
        record[:line]=[current.extend(Prt)]
        ver(current)
        macro(record)
        self[:stat]='(done)'
        super
      }
      self
    end

    # Should be public for recursive call
    def macro(record,depth=1)
      self[:stat]='(run)'
      @select.each{|e1|
        current={'depth'=>depth}.update(e1)
        record[:line].push(current.extend(Prt))
        case e1['type']
        when 'goal'
          self[:stat]='(done)' unless fault?(current)
          ver(current)
        when 'check'
          self[:stat]="(error)" if fault?(current)
          ver(current)
        when 'wait'
          ver(current.title)
          waiting(current){ver('.')}
          ver(current.result)
        when 'exec'
          ver(current)
          self[:stat]="(query)"
          sleep unless @opt['n']
          self[:stat]='(run)'
          @aint[e1['site']].exe(e1['cmd'])
        when 'mcr'
          ver(current)
          sub=@index.dup.set(e1['mcr']).macro(record,depth+1)
        end
        current.delete('stat')
        current['elapsed']=elapsed(record[:time])
        self[:stat] != '(run)' && live?(depth) && break
      }
      self
    end

    private
    def elapsed(base)
      "%.3f" % (Time.now.to_f-base)
    end

    def ver(str)
      print str if @opt['v']
    end

    def live?(depth)
      if @opt['t']
        Msg.hidden('Dryrun:Proceed',depth) if @opt['v']
        false
      else
        true
      end
    end

    def waiting(current)
      self[:stat]="(wait)"
      #gives number or nil(if break)
      if current['retry'].to_i.times{|n|
          current['retry']=n
          brk=fault?(current)
          break if @opt['t'] && n > 4 || brk
          sleep 1
          yield
        }
        current['timeout']=true
        self[:stat]='(timeout)'
      else
        current.delete('fault')
        self[:stat]='(run)'
      end
    end

    def fault?(current)
      flt={}
      res=!current['stat'].all?{|h|
        flt['site']=h['site']
        break unless flt['upd']=update?(flt['site'])
        ['var','val','inv'].each{|k| flt[k]=h[k] }
        if res=getstat(flt['site'],flt['var'])
          flt['res']=res
          flt['upd'] && comp(res,flt['val'],flt['inv'])
        end
      } && current['fault']=flt
      res
    end

    # aint is forced to be localhost
    def update?(ins)
      stat=@aint[ins].stat.load
      stat.update?
    end

    def getstat(ins,var)
      stat=@aint[ins].stat
      res=stat['msg'][var]||stat['val'][var]
      Cmd.msg{"ins=#{ins},var=#{var},res=#{res}"}
      Cmd.msg{stat['val']}
      res
    end

    def comp(res,val,inv)
      i=(/true|1/ === inv)
      if /[a-zA-Z]/ === val
        (/#{val}/ === res) ^ i
      else
        (val == res) ^ i
      end
    end
  end
end

class Command::ExtDom
  def ext_mcrcmd(aint,logs,opt={})
    values.each{|item|
      item.extend(Mcr::Cmd).ext_mcrcmd(aint,logs,opt)
    }
    self
  end
end

if __FILE__ == $0
  require "libmcrdb"
#  ENV['VER']='appsv'

  opt=Msg::GetOpts.new("tn")
  id,*cmd=ARGV
  ARGV.clear
  opt['v']=true
  begin
    logs=[]
    app=App::List.new
    mdb=Mcr::Db.new(id) #ciax
    mcobj=Command.new
    mcobj.add_extdom(mdb,:macro).ext_mcrcmd(app,logs,opt)
    mcobj.set(cmd).exe
    logs.last[:thread].join
    puts Msg.view_struct(logs)
  rescue InvalidCMD
    opt.usage("[mcr] [cmd] (par)")
  rescue UserError
    Msg.exit(3)
  end
end
