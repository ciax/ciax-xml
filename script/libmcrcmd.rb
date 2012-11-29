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
    attr_reader :logline
    def self.extended(obj)
      init_ver('McrCmd',9)
      Msg.type?(obj,Command::ExtItem)
    end

    def init(aint,opt={})
      @aint=Msg.type?(aint,App::List)
      @opt=Msg.type?(opt,Hash)
      @logline=ExHash.new
      self
    end

    def exe
      @tid=Thread.new{
        @logline=ExHash.new
        @logline[:tid]=Time.new.to_f
        current={'type'=>'mcr','mcr'=>@cmd,'label'=>self[:label]}
        @logline[:line]=[current.extend(Prt)]
        ver(current)
        macro
        super
      }
      self
    end

    def join
      @tid.join
      self
    end

    private
    def macro(depth=1)
      self[:msg]='(run)'
      @select.each{|e1|
        current={'depth'=>depth}.update(e1)
        @logline[:line].push(current.extend(Prt))
        case e1['type']
        when 'goal'
          self[:msg]='(done)' unless fault?(current)
          ver(current)
        when 'check'
          self[:msg]="(error)" if fault?(current)
          ver(current)
        when 'wait'
          ver(current.title)
          waiting(current){ver('.')}
          ver(current.result)
        when 'exec'
          ver(current)
          self[:msg]="(query)"
          #sleep
          self[:msg]='(run)'
          @aint[e1['site']].exe(e1['cmd'])
        when 'mcr'
          ver(current)
          @index.dup.set(e1['mcr']).macro(depth+1)
        end
        current.delete('stat')
        current.delete('tid')
        self[:msg] != '(run)' && live?(depth) && break
      }
    end

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
      self[:msg]="(wait)"
      #gives number or nil(if break)
      if current['retry'].to_i.times{|n|
          current['retry']=n
          brk=fault?(current)
          break if @opt['t'] && n > 4 || brk
          sleep 1
          yield
        }
        current['timeout']=true
        self[:msg]='(timeout)'
      else
        current.delete('fault')
        self[:msg]='(run)'
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
      current['elapsed']=elapsed(@logline[:tid])
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
  def ext_mcrcmd(aint,dr=nil)
    values.each{|item|
      item.extend(Mcr::Cmd).init(aint,dr)
    }
    self
  end
end

if __FILE__ == $0
  require "libmcrdb"
#  ENV['VER']='appsv'

  opt=Msg::GetOpts.new("tv")
  id,*cmd=ARGV
  ARGV.clear
  begin
    app=App::List.new
    mdb=Mcr::Db.new(id) #ciax
    mcobj=Command.new
    mcobj.add_ext(mdb,:macro).ext_mcrcmd(app,opt)
    puts mcobj.set(cmd).exe.join.logline
  rescue InvalidCMD
    opt.usage("[mcr] [cmd] (par)")
  rescue UserError
    Msg.exit(3)
  end
end
