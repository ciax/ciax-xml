#!/usr/bin/ruby
require "libmcrsh"
require "libapplist"

module Mcr
  class Sv < Exe
    extend Msg::Ver
    def initialize(mdb,client)
      super(mdb)
      @act=1
      @client=Msg.type?(client,App::List)
      @index=0
      $opt['t']=true
      @tid=Time.now.to_i
      @extcmd.init_proc{|mitm|
        self[:cid]=mitm[:cid]
        macro(mitm)
      }
    end

    def to_s
      Msg.view_struct(@logline)
    end

    def macro(mitm)
      self[:stat]='(run)'
      loop{
        unless e1=mitm.select[@index]
          self[:stat]='(done)'
          return 'done'
        end
        @index+=1
        @last={'tid'=>@tid,'cid'=>self[:cid]}
        @logline.push(@last)
        @last.update(e1).delete('stat')
        case e1['type']
        when 'break'
          !fault?(e1) && @act && break
        when 'check'
          fault?(e1) && @act && raise(UserError)
        when 'wait'
          self[:stat]="(wait)"
          if e1['retry'].to_i.times{|n|
            sleep 1 if @act > 0 && n > 0
            @last['retry']=n
            fault?(e1) || break
          }
          @last['timeout']=true
          @act && raise(UserError)
          else
            @last.delete('fault')
          end
        when 'mcr','exec'
          self[:stat]="(stop)"
          return e1
        end
      }
    rescue UserError
      self[:stat]="(error)"
    rescue Broken
      self[:stat]="(broken)"
    end

    private
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

  id,*cmd=ARGV
  ARGV.clear
  begin
    app=App::List.new{|ldb,fl|
      App::Test.new(ldb[:app])
    }
    mdb=Mcr::Db.new(id)
    puts Mcr::Sv.new(mdb,app).exe(cmd)
  rescue InvalidCMD
    Msg.exit(2)
  rescue InvalidID
    Msg.usage("[mcr] [cmd] (par)",*$optlist)
  rescue UserError
    Msg.exit(3)
  end
end
