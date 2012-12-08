#!/usr/bin/ruby
require "libapplist"
require "libcmdext"
require "libmcrprt"

module Mcr
  class Record < Hash
    extend Msg::Ver
    def initialize(aint,opt={})
      @aint=Msg.type?(aint,App::List)
      @opt=Msg.type?(opt,Hash)
      @base=Time.new.to_f
      self[:id]=@base.to_i
      self[:stat]='(ready)'
      self[:total]=0
      self[:sequence]=[]
    end

    def newline(db,depth=0)
      @crnt={'depth' => depth}.update(db).extend(Prt)
      @crnt['elapsed']="%.3f" % (Time.now.to_f-@base)
      self[:sequence] << @crnt
      self
    end

    def fin
      self[:total]="%.3f" % (Time.now.to_f-@base)
      self
    end

    def prt(num=nil)
      if @opt['v']
        case num
        when 0
          print @crnt.title
        when 1
          print @crnt.result
        else
          print @crnt
        end
      end
    end

    def waiting
      self[:stat]="(wait)"
      #gives number or nil(if break)
      @crnt['max']=@crnt['retry']
      if @crnt['retry'].to_i.times{|n|
          @crnt['retry']=n
          break 1 if  @opt['t'] && n > 3
          break if ok?(1)
          sleep 1
          yield if @opt['v']
        }
        @crnt['timeout']=true
        self[:stat]='(timeout)'
      else
        self[:stat]='(run)'
      end
    end

    def ok?(refr=nil)
      res=(flt=scan).empty?
      @crnt['fault']=flt unless res
      @crnt.delete('stat') if res or !refr
      refresh if refr
      res
    end

    private
    def scan
      stats=load
      @crnt['stat'].map{|h|
        flt={}
        site=flt['site']=h['site']
        stat=stats[site]
        if flt['upd']=stat.update?
          inv=flt['inv']=h['inv']
          var=flt['var']=h['var']
          cmp=flt['cmp']=h['val']
          res=stat['msg'][var]||stat['val'][var]
          Record.msg{"site=#{site},var=#{var},inv=#{inv},cmp=#{cmp},res=#{res}"}
          next unless res
          flt['res']=res
          match?(res,cmp,flt['inv']) && flt || nil
        else
          flt
        end
      }.compact
    end

    def load
      stats={}
      sites.each{|site|
        stats[site]=@aint[site].stat.load
      }
      stats
    end

    def refresh
      sites.each{|site|
        @aint[site].stat.refresh
      }
      @crnt
    end

    def sites
      @crnt['stat'].map{|h| h['site']}.uniq
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

  module Cmd
    extend Msg::Ver
    # @<< (index),(id*),(par*),cmd*,(def_proc*)
    # @< select*
    # @ aint,opt,exec
    attr_reader :record
    def @crnt.extended(obj)
      init_ver('McrCmd',9)
      Msg.type?(obj,Command::ExtItem)
    end

    def ext_mcrcmd(aint,opt={})
      @aint=Msg.type?(aint,App::List)
      @opt=Msg.type?(opt,Hash)
      @record=Record.new(aint,opt)
      @exec=nil
      self
    end

    def exe
      @record.newline({'type'=>'mcr','mcr'=>@cmd,'label'=>self[:label]})
      @record.prt
      macro(@record)
      @record[:stat]='(done)'
      super
    rescue Interlock
      @record[:stat]='(fail)'
    rescue Broken,Interrupt
      warn @exec.exe(['interrupt'])['msg'] if @exec
      @record[:stat]='(broken)'
      Thread.exit
    ensure
      @record.fin
      self
    end

    # Should be public for recursive call
    def macro(rec,depth=1)
      rec[:stat]='(run)'
      @select.each{|e1|
        rec.newline(e1,depth)
        case e1['type']
        when 'goal'
          rec[:stat]='(done)' if rec.ok?
          rec.prt
        when 'check'
          rec[:stat]='(fail)' unless rec.ok?
          rec.prt
        when 'wait'
          rec.prt(0)
          rec.waiting{print('.')}
          rec.prt(1)
        when 'exec'
          rec.prt
          rec[:stat]="(query)"
          query(depth)
          rec[:stat]='(run)'
          @exec=@aint[e1['site']].exe(e1['cmd'])
          @exec.stat.refresh
        when 'mcr'
          rec.prt
          sub=@index.dup.setcmd(e1['mcr']).macro(rec,depth+1)
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
    item=mcobj.setcmd(cmd).exe
    puts Msg.view_struct(item.record)
  rescue InvalidCMD
    opt.usage("[mcr] [cmd] (par)")
  rescue UserError
    Msg.exit(3)
  ensure
  end
end
