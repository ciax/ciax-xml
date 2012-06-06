#!/usr/bin/ruby
require "libmsg"
require "libcommand"
require "libapplist"

class Broken < RuntimeError;end

module Mcr
  class Sub < Array
    extend Msg::Ver
    ACT=ENV['ACT'].to_i
    @@client=App::List.new
    def initialize(cobj,int=nil)
      Sub.init_ver(self,9)
      @int=int
      @cobj=Msg.type?(cobj,Command)
      @line=[]
      case ACT
      when 0...1
        $opt['t']=true
      when 1...2
        $opt['l']=true
      end
    end

    def macro(cmd)
      cobj=@cobj.dup.set(cmd)
      @line.clear
      #Thread.abort_on_exception=true
      push Thread.new(cobj){|c|
        crnt=Thread.current
        crnt[:obj]=self
        crnt[:tid]=Time.now.to_i
        crnt[:cid]=c[:cid]
        begin
          crnt[:stat]='run'
          submacro(c,1)
          crnt[:stat]='done'
        rescue UserError
          crnt[:stat]="error"
        rescue Broken
          crnt[:stat]="broken"
        end
      }
      self
    end

    def to_s
      Msg.view_struct(@line)
    end

    def join
      each{|t| t.join}
    end

    private
    def submacro(cobj,depth,ins=nil)
      cobj[:select].each{|e1|
        @last={'tid'=>Thread.current[:tid],'cid'=>cobj[:cid],'depth'=>depth}
        @line.push(@last)
        @last.update(e1).delete('stat')
        case e1['type']
        when 'break'
          !fault?(e1,ins) && ENV['ACT'] && break
        when 'check'
          fault?(e1,ins) && ENV['ACT'] && raise(UserError)
        when 'wait'
          if e1['retry'].to_i.times{|n|
            sleep 1 if ACT > 0 && n > 0
            @last['retry']=n
            fault?(e1,ins) || break
          }
          @last['timeout']=true
          ENV['ACT'] && raise(UserError)
          else
            @last.delete('fault')
          end
        when 'mcr'
          if /true|1/ === e1['async']
            clone.clear.macro(e1['cmd'])
          else
            subc=cobj.dup.set(e1['cmd'])
            submacro(subc,depth+1,e1['ins']||ins)
          end
        when 'exec'
          exe(e1['cmd'],e1['ins']||ins)
        end
      }
      self
    end

    def fault?(e,ins)
      flt={}
      !e['stat'].all?{|h|
        flt['ins']=h['ins']||ins
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
      stat=@@client[ins].stat.load
      stat.update?
    end

    def getstat(ins,var)
      stat=@@client[ins].stat
      res=stat['msg'][var]||stat.val[var]
      Sub.msg{"ins=#{ins},var=#{var},res=#{res}"}
      Sub.msg{stat.val}
      res
    end

    def exe(cmd,ins)
      Thread.current[:stat]="wait"
      sleep if @int
      Thread.current[:stat]="run"
      @@client.each{|k,v| v.stat.refresh }
      @@client[ins].exe(cmd)
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

  Msg.getopts("r")
  id,*cmd=ARGV
  ARGV.clear
  begin
    mdb=Mcr::Db.new(id)
    cobj=Command.new(mdb[:macro])
    mcr=Mcr::Sub.new(cobj)
    mcr.extend(Mcr::Prt) unless $opt['r']
    mcr.macro(cmd).join
    puts mcr.to_s
  rescue InvalidCMD
    Msg.exit(2)
  rescue InvalidID
    Msg.usage("(opt) [mcr] [cmd] (par)",*$optlist)
  rescue UserError
    Msg.exit(3)
  end
end
