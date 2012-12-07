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
      current={'type'=>'mcr','mcr'=>@cmd,'label'=>self[:label]}
      rec[:sequence]=[current.extend(Prt)]
      display(current)
      macro(base)
      rec[:stat]='(done)'
      super
      self
    rescue Broken,Interrupt
      warn @exec.exe(['interrupt'])['msg'] if @exec
      rec[:stat]='(broken)'
      Thread.exit
    end

    # Should be public for recursive call
    def macro(base,depth=1)
      rec=Thread.current[:record]
      rec[:stat]='(run)'
      @select.each{|e1|
        current={'depth'=>depth}.update(e1).extend(Prt)
        rec[:sequence].push(current)
        case e1['type']
        when 'goal'
          rec[:stat]='(done)' unless fault?(current)
          display(current)
        when 'check'
          rec[:stat]="(error)" if fault?(current)
          display(current)
        when 'wait'
          display(current.title)
          waiting(current){display('.')}
          display(current.result)
        when 'exec'
          display(current)
          rec[:stat]="(query)"
          query(depth)
          rec[:stat]='(run)'
          @exec=@aint[e1['site']].exe(e1['cmd'])
          @exec.stat.refresh
        when 'mcr'
          display(current)
          sub=@index.dup.setcmd(e1['mcr']).macro(base,depth+1)
        end
        current.delete('stat')
        current['elapsed']="%.3f" % (Time.now.to_f-base)
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

    def waiting(current)
      rec=Thread.current[:record]
      rec[:stat]="(wait)"
      #gives number or nil(if break)
      current['max']=current['retry']
      if current['retry'].to_i.times{|n|
          current['retry']=n
          break 1 if n > 3 if @opt['t']
          break unless fault?(current)
          refresh(current)
          sleep 1
          yield
        }
        current['timeout']=true
        rec[:stat]='(timeout)'
      else
        current.delete('fault')
        rec[:stat]='(run)'
      end
    end

    def fault?(current)
      flt={}
      stats={}
      current['stat'].map{|h| h['site']}.uniq.each{|site|
        stats[site]=@aint[site].stat.load
      }
      flg=!current['stat'].all?{|h|
        site=flt['site']=h['site']
        stat=stats[site]
        break unless flt['upd']=stat.update?
        inv=flt['inv']=h['inv']
        var=flt['var']=h['var']
        cmp=flt['cmp']=h['val']
        res=stat['msg'][var]||stat['val'][var]
        Cmd.msg{"site=#{site},var=#{var},inv=#{inv},cmp=#{cmp},res=#{res}"}
        if res
          flt['res']=res
          flt['upd'] && match?(res,cmp,flt['inv'])
        end
      } && current['fault']=flt
      flg
    end

    def refresh(current)
      current['stat'].map{|h| h['site']}.uniq.each{|site|
        @aint[site].stat.refresh
      }
      self
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
