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

    def ext_mcrcmd(aint,opt={})
      @aint=Msg.type?(aint,App::List)
      @opt=Msg.type?(opt,Hash)
      Thread.current[:stat]='(ready)'
      self
    end

    def exe
      me=Thread.current
      base=Time.new.to_f
      current={'base'=>base.to_i,'type'=>'mcr','mcr'=>@cmd,'label'=>self[:label]}
      me[:record]=[current.extend(Prt)]
      display(current)
      macro(base)
      me[:stat]='(done)'
      super
      self
    end

    # Should be public for recursive call
    def macro(base,depth=1)
      me=Thread.current
      me[:stat]='(run)'
      @select.each{|e1|
        current={'depth'=>depth}.update(e1)
        me[:record].push(current.extend(Prt))
        case e1['type']
        when 'goal'
          me[:stat]='(done)' unless fault?(current)
          display(current)
        when 'check'
          me[:stat]="(error)" if fault?(current)
          display(current)
        when 'wait'
          display(current.title)
          waiting(current){display('.')}
          display(current.result)
        when 'exec'
          display(current)
          me[:stat]="(query)"
          query(depth)
          me[:stat]='(run)'
          @aint[e1['site']].exe(e1['cmd']).stat.refresh
        when 'mcr'
          display(current)
          sub=@index.dup.set(e1['mcr']).macro(base,depth+1)
        end
        current.delete('stat')
        current['elapsed']="%.3f" % (Time.now.to_f-base)
        me[:stat] != '(run)' && live?(depth) && break
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
        Msg.alert("Quit") unless /[Yy]/ === res
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
      me=Thread.current
      me[:stat]="(wait)"
      #gives number or nil(if break)
      current['max']=current['retry']
      if current['retry'].to_i.times{|n|
          current['retry']=n
          if @opt['t']
            break if n > 4
          else
            break if fault?(current)
          end
          sleep 1
          yield
        }
        current['timeout']=true
        me[:stat]='(timeout)'
      else
        current.delete('fault')
        me[:stat]='(run)'
      end
    end

    def fault?(current)
      flt={}
      flg=!current['stat'].all?{|h|
        site=flt['site']=h['site']
        stat=@aint[site].stat.load
        break unless flt['upd']=stat.update?
        inv=flt['inv']=h['inv']
        var=flt['var']=h['var']
        cmp=flt['cmp']=h['val']
        res=stat['msg'][var]||stat['val'][var]
        Cmd.msg{"site=#{site},var=#{var},inv=#{inv},cmp=#{cmp},res=#{res}"}
        if res
          flt['res']=res
          flt['upd'] && comp(res,cmp,flt['inv'])
        end
      } && current['fault']=flt
      flg
    end

    def comp(res,cmp,inv)
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
    puts Msg.view_struct(Thread.current[:record])
  rescue InvalidCMD
    opt.usage("[mcr] [cmd] (par)")
  rescue UserError
    Msg.exit(3)
  end
end
