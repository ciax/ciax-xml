#!/usr/bin/ruby
require "libmcrexe"
require "libapplist"
require "libmcrprt"

module Mcr
  class Sv < Exe
    extend Msg::Ver
    def initialize(mdb,client,dr=nil)
      super(mdb)
      #@<< cobj,intcmd,int_proc,upd_proc*
      #@< mdb,extcmd,logline*
      @dryrun=dr
      @client=Msg.type?(client,App::List)
      @extcmd.init_proc{|mitm|
        tid=Time.now.to_f
        @line=[]
        @logline[tid.to_i]={:cid => mitm[:cid], :line => @line}
        self[:cid]=mitm[:cid]
        macro(mitm,tid)
      }
    end

    def to_s
      Msg.view_struct(@logline)
    end

    def macro(mitm,tid,depth=1)
      Msg.type?(mitm,Command::Item)
      self[:stat]='(run)'
      mitm.select.each{|e1|
        current={'depth'=>depth}.update(e1).extend(Mcr::Prt)
        @line.push(current)
        print current.title
        case e1['type']
        when 'break'
          self[:stat]='(done)' unless fault?(current,tid)
        when 'check'
          self[:stat]="(error)" if fault?(current,tid)
        when 'wait'
          self[:stat]="(wait)"
          if waiting(current,tid)
            self[:stat]='(run)'
          else
            self[:stat]='(timeout)'
          end
        when 'exec'
          puts
          @client[e1['site']].exe(e1['cmd'])
          next
        when 'mcr'
          puts
          macro(@cobj.dup.set(e1['cmd']),tid,depth+1)
          next
        end
        current.delete('stat')
        puts current.result
        self[:stat] != '(run)' && dryrun(depth) && break
      }
    end

    private
    def elapsed(base)
      "%.3f" % (Time.now.to_f-base)
    end

    def dryrun(depth)
      if @dryrun
        warn('  '*depth+Msg.color('Dryrun:Proceed',8))
        false
      else
        true
      end
    end

    def waiting(current,tid)
      #gives number or nil(if break)
      current['retry'].to_i.times{|n|
        current['retry']=n
        brk=fault?(current,tid)
        break if @dryrun && n > 4 || brk
        sleep 1
        print '.'
      } && current['timeout']=true || current.delete('fault')
    end

    def fault?(current,tid)
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
      current['elapsed']=elapsed(tid)
      res
    end

    # client is forced to be localhost
    def update?(ins)
      stat=@client[ins].stat.load
      stat.update?
    end

    def getstat(ins,var)
      stat=@client[ins].stat
      res=stat['msg'][var]||stat.val[var]
      Sv.msg{"ins=#{ins},var=#{var},res=#{res}"}
      Sv.msg{stat.val}
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

if __FILE__ == $0
  require "libmcrdb"
#  ENV['VER']='appsv'

  opt=Msg::GetOpts.new("t")
  id,*cmd=ARGV
  ARGV.clear
  begin
    app=App::List.new
    mdb=Mcr::Db.new(id) #ciax
    mcr=Mcr::Sv.new(mdb,app,opt['t'])
    puts mcr.exe(cmd)
    puts mcr[:stat]
  rescue InvalidCMD
    Msg.exit(2)
  rescue InvalidID
    opt.usage("[mcr] [cmd] (par)")
  rescue UserError
    Msg.exit(3)
  end
end
