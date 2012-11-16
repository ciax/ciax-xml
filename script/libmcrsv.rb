#!/usr/bin/ruby
require "libmcrexe"
require "libapplist"

module Mcr
  class Sv < Exe
    extend Msg::Ver
    def initialize(mdb,client,dr=nil)
      super(mdb)
      @dryrun=dr
      @client=Msg.type?(client,App::List)
      @extcmd.init_proc{|mitm|
        @tid=Time.now.to_i
        @index=0
        @line=[]
        @logline[@tid]={:cid => mitm[:cid], :list => @line}
        self[:cid]=mitm[:cid]
        macro(mitm)
      }
    end

    def to_s
      Msg.view_struct(@logline)
    end

    def macro(mitm,depth=1)
      self[:stat]='(run)'
      while e1=mitm.select[@index]
        @index+=1
        @last={'depth'=>depth}.extend(ExEnum)
        @line.push(@last)
        @last.update(e1).delete('stat')
        case e1['type']
        when 'break'
          !fault?(e1) && dryrun('No Skip') && break
        when 'check'
          fault?(e1) && dryrun('Force Pass') && raise(UserError)
        when 'wait'
          self[:stat]="(wait)"
          if e1['retry'].to_i.times{|n|
              sleep 1 if n > 0
              @last['retry']=n
              fault?(e1) || break
            } #gives number or nil(if break)
            @last['timeout']=true
            dryrun('No Timeout') && raise(UserError)
          else
            @last.delete('fault')
          end
        when 'exec'
#warn e1['ins']
          @client[e1['ins']].exe(e1['cmd'])
        when 'mcr'
#          exe(e1['cmd'])
warn 'submacro'
        end
      warn single(@last)
      end
      self[:stat]='(done)'
    rescue UserError
      self[:stat]="(error)"
    rescue Broken
      self[:stat]="(broken)"
    end

    private
    def dryrun(str)
      if @dryrun
        Msg.warn('Dryrun:'+str)
        false
      else
        true
      end
    end

    def fault?(e)
      flt={}
      !e['stat'].all?{|h|
        flt['ins']=h['ins']
        break unless flt['upd']=update?(flt['ins'])
        ['var','val','inv'].each{|k| flt[k]=h[k] }
        if res=getstat(flt['ins'],flt['var'])
          flt['res']=res
          flt['upd'] && comp(res,flt['val'],flt['inv'])
        end
      } && @last['fault']=flt
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
  require "libmcrprt"
  ENV['VER']='appsv'

  id,*cmd=ARGV
  ARGV.clear
  begin
    app=App::List.new
    mdb=Mcr::Db.new(id) #ciax
    mcr=Mcr::Sv.new(mdb,app,true).extend(Mcr::Prt)
    mcr.exe(cmd)
  rescue InvalidCMD
    Msg.exit(2)
  rescue InvalidID
    Msg.usage("[mcr] [cmd] (par)")
  rescue UserError
    Msg.exit(3)
  end
end
