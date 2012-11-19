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
        @tid=Time.now.to_i
        @line=[]
        @logline[@tid]={:cid => mitm[:cid], :line => @line}
        self[:cid]=mitm[:cid]
        macro(mitm)
      }
    end

    def to_s
      Msg.view_struct(@logline)
    end

    def macro(mitm,depth=1)
      Msg.type?(mitm,Command::Item)
      self[:stat]='(run)'
      mitm.select.each{|e1|
        current={'depth'=>depth}.extend(Mcr::Prt)
        @line.push(current)
        current.update(e1).delete('stat')
        case e1['type']
        when 'break'
          res=!fault?(e1,current)
          puts current
          res && dryrun(depth) && break
        when 'check'
          res=fault?(e1,current)
          puts current
          res && dryrun(depth) && raise(UserError)
        when 'wait'
          print current.title
          self[:stat]="(wait)"
          if e1['retry'].to_i.times{|n|
              sleep 1 if n > 0
              print '.'
              current['retry']=n
              if @dryrun
                break if n > 4
              else
                fault?(e1,current) || break
              end
            } #gives number or nil(if break)
            current['timeout']=true
            dryrun(depth) && raise(UserError)
          else
            current.delete('fault')
          end
          puts current.result
        when 'exec'
          puts current.title
          @client[e1['site']].exe(e1['cmd'])
        when 'mcr'
          puts current.title
          macro(@cobj.dup.set(e1['cmd']),depth+1)
        end
      }
      self[:stat]='(done)'
    rescue UserError
      self[:stat]="(error)"
    rescue Broken
      self[:stat]="(broken)"
    end

    private
    def dryrun(depth)
      if @dryrun
        warn('  '*depth+Msg.color('Dryrun:Proceed',8))
        false
      else
        true
      end
    end

    def fault?(e,current)
      flt={}
      !e['stat'].all?{|h|
        flt['site']=h['site']
        break unless flt['upd']=update?(flt['site'])
        ['var','val','inv'].each{|k| flt[k]=h[k] }
        if res=getstat(flt['site'],flt['var'])
          flt['res']=res
          flt['upd'] && comp(res,flt['val'],flt['inv'])
        end
      } && current['fault']=flt
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

  id,*cmd=ARGV
  ARGV.clear
  begin
    app=App::List.new
    mdb=Mcr::Db.new(id) #ciax
    mcr=Mcr::Sv.new(mdb,app,true)
    mcr.exe(cmd)
  rescue InvalidCMD
    Msg.exit(2)
  rescue InvalidID
    Msg.usage("[mcr] [cmd] (par)")
  rescue UserError
    Msg.exit(3)
  end
end
