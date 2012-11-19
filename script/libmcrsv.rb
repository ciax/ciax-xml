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
        current={'depth'=>depth}.update(e1).extend(Mcr::Prt)
        @line.push(current)
        print current.title
        case e1['type']
        when 'break'
          self[:stat]='(done)' unless fault?(current)
        when 'check'
          self[:stat]="(error)" if fault?(current)
        when 'wait'
          self[:stat]="(wait)"
          if e1['retry'].to_i.times{|n|
              current['retry']=n
              brk=fault?(current)
              break if @dryrun && n > 4 || brk
              sleep 1
              print '.'
            } #gives number or nil(if break)
            current['timeout']=true
            self[:stat]='(timeout)'
          else
            current.delete('fault')
          end
        when 'exec'
          puts
          @client[e1['site']].exe(e1['cmd'])
          next
        when 'mcr'
          puts
          macro(@cobj.dup.set(e1['cmd']),depth+1)
          next
        end
        current.delete('stat')
        puts current.result
        self[:stat] != '(run)' && dryrun(depth) && break
      }
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

    def fault?(current)
      flt={}
      !current['stat'].all?{|h|
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
    puts mcr.exe(cmd)
  rescue InvalidCMD
    Msg.exit(2)
  rescue InvalidID
    Msg.usage("[mcr] [cmd] (par)")
  rescue UserError
    Msg.exit(3)
  end
end
