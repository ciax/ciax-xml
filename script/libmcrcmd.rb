#!/usr/bin/ruby
require "libapplist"
require "libcmdext"
require "libmcrprt"

module Mcr
  module Cmd
    extend Msg::Ver
    # @<< (index),(id*),(par*),cmd*,(def_proc*)
    # @< select*
    # @ aint,opt,exec
    def self.extended(obj)
      init_ver('McrCmd',9)
      Msg.type?(obj,Command::ExtItem)
    end

    def ext_mcrcmd(aint,opt={})
      @aint=Msg.type?(aint,App::List)
      @opt=Msg.type?(opt,Hash)
      @exec=nil
      self
    end

    def exe
      base=Time.new.to_f
      rec=(Thread.current[:record]||={})
      rec.update({:id =>base.to_i,:stat => '(ready)'})
      crnt={'type'=>'mcr','mcr'=>@cmd,'label'=>self[:label]}
      rec[:sequence]=[crnt.extend(Prt)]
      display(crnt)
      macro(base)
      rec[:stat]='(done)'
      super
    rescue Interlock
      rec[:stat]='(fail)'
    rescue Broken,Interrupt
      warn @exec.exe(['interrupt'])['msg'] if @exec
      rec[:stat]='(broken)'
      Thread.exit
    ensure
      rec[:total]="%.3f" % (Time.now.to_f-base)
      self
    end

    # Should be public for recursive call
    def macro(base,depth=1)
      rec=Thread.current[:record]
      rec[:stat]='(run)'
      @select.each{|e1|
        crnt={'depth'=>depth}.update(e1).extend(Prt)
        crnt['elapsed']="%.3f" % (Time.now.to_f-base)
        rec[:sequence].push(crnt)
        case e1['type']
        when 'goal'
          rec[:stat]='(done)' if ok?(crnt)
          display(crnt)
        when 'check'
          rec[:stat]='(fail)' unless ok?(crnt)
          display(crnt)
        when 'wait'
          display(crnt.title)
          waiting(crnt){display('.')}
          display(crnt.result)
          crnt.delete('stat')
        when 'exec'
          display(crnt)
          rec[:stat]="(query)"
          query(depth)
          rec[:stat]='(run)'
          @exec=@aint[e1['site']].exe(e1['cmd'])
          @exec.stat.refresh
        when 'mcr'
          display(crnt)
          sub=@index.dup.setcmd(e1['mcr']).macro(base,depth+1)
        end
        rec[:stat] != '(run)' && live?(depth) && break
      }
      self
    end

    private
    def display(str)
      print str if @opt['v']
    end

    def query(depth)
      if @opt['v']
        prompt='  '*depth+Msg.color("Proceed?[Y/N]",5)
        true while (res=Readline.readline(prompt,true)).empty?
        raise Broken unless /[Yy]/ === res
      elsif !@opt['n']
        sleep
      end
    end

    def live?(depth)
      if @opt['t']
        Msg.hidden('Dryrun:Proceed',depth) if @opt['v']
        false
      else
        true
      end
    end

    def waiting(crnt)
      rec=Thread.current[:record]
      rec[:stat]="(wait)"
      #gives number or nil(if break)
      crnt['max']=crnt['retry']
      if crnt['retry'].to_i.times{|n|
          crnt['retry']=n
          break 1 if  @opt['t'] && n > 3
          break if ok?(crnt,1)
          sleep 1
          yield
        }
        crnt['timeout']=true
        rec[:stat]='(timeout)'
      else
        crnt.delete('fault')
        rec[:stat]='(run)'
      end
    end

    def ok?(crnt,refresh=nil)
      res=(flt=scan(crnt)).empty?
      crnt['fault']=flt unless res
      crnt.delete('stat') if res or !refresh
      refresh(crnt) if refresh
      res
   end

    def scan(crnt)
      stats=load(crnt)
      crnt['stat'].map{|h|
        flt={}
        site=flt['site']=h['site']
        stat=stats[site]
        if flt['upd']=stat.update?
          inv=flt['inv']=h['inv']
          var=flt['var']=h['var']
          cmp=flt['cmp']=h['val']
          res=stat['msg'][var]||stat['val'][var]
          Cmd.msg{"site=#{site},var=#{var},inv=#{inv},cmp=#{cmp},res=#{res}"}
          next unless res
          flt['res']=res
          match?(res,cmp,flt['inv']) && flt
        else
          flt
        end
      }.compact
    end

    def load(crnt)
      stats={}
      sites(crnt).each{|site|
        stats[site]=@aint[site].stat.load
      }
      stats
    end

    def refresh(crnt)
      sites(crnt).each{|site|
        @aint[site].stat.refresh
      }
      self
    end

    def sites(crnt)
      crnt['stat'].map{|h| h['site']}.uniq
    end

    def match?(res,cmp,inv)
      i=(/true|1/ === inv)
      if /[a-zA-Z]/ === cmp
        (/#{cmp}/ === res) ^ i
      else
        (cmp == res) ^ i
      end
    end
  end
end

class Command::ExtDom
  def ext_mcrcmd(aint,opt={})
    values.each{|item|
      item.extend(Mcr::Cmd).ext_mcrcmd(aint,opt)
    }
    self
  end
end

if __FILE__ == $0
  require "libmcrdb"

  opt=Msg::GetOpts.new("tn")
  id,*cmd=ARGV
  ARGV.clear
  opt['v']=true
  begin
    app=App::List.new
    mdb=Mcr::Db.new(id) #ciax
    mcobj=Command.new
    mcobj.add_extdom(mdb,:macro).ext_mcrcmd(app,opt)
    mcobj.setcmd(cmd).exe
  rescue InvalidCMD
    opt.usage("[mcr] [cmd] (par)")
  rescue UserError
    Msg.exit(3)
  ensure
    rec=Thread.current[:record]
    puts Msg.view_struct(rec) if rec
  end
end
