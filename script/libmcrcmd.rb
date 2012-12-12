#!/usr/bin/ruby
require "libapplist"
require "libcmdext"
require "libmcrblk"

module Mcr
  module Cmd
    extend Msg::Ver
    # @<< (index),(id*),(par*),cmd*,(def_proc*)
    # @< select*
    # @ aint,opt,interrupt
    attr_reader :record,:exec
    def self.extended(obj)
      init_ver('McrCmd',9)
      Msg.type?(obj,Command::ExtItem)
    end

    def ext_mcrcmd(record,opt={})
      @opt=Msg.type?(opt,Hash)
      @record=Msg.type?(record,Block)
      @exec=Update.new
      @interrupt=Update.new
      self
    end

    def exe
      @record.newline({'type'=>'mcr','mcr'=>@cmd,'label'=>self[:label]})
      @record.crnt.prt
      macro(@record)
      super
    rescue Interlock
      @record[:stat]='(fail)'
    rescue Broken,Interrupt
      warn @interrupt.exe['msg']
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
          if rec.crnt.ok?
            rec[:stat]='(done)'
            live?(depth) && break
          end
          rec.crnt.prt
        when 'check'
          unless rec.crnt.ok?
            rec[:stat]='(fail)'
            live?(depth) && raise(Interlock)
          end
          rec.crnt.prt
        when 'wait'
          rec.crnt.prt(0)
          rec.waiting{print('.')}
          rec.crnt.prt(1)
        when 'exec'
          rec.crnt.prt
          rec[:stat]="(query)"
          query(depth)
          rec[:stat]='(run)'
          exe=@exec.exe([e1['site'],e1['cmd']])
          @interrupt.clear.add{exe.exe(['interrupt'])}
        when 'mcr'
          rec.crnt.prt
          sub=@index.dup.setcmd(e1['mcr']).macro(rec,depth+1)
        end
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
      load=Update.new.add{|site| aint[site].stat.load}
      refresh=Update.new.add{|site| aint[site].stat.refresh}
      record=Mcr::Block.new(load,refresh,opt)
      item.extend(Mcr::Cmd).ext_mcrcmd(record,opt)
      item.exec.add{|site,cmd| aint[site].exe(cmd).stat.refresh}
    }
    self
  end
end

if __FILE__ == $0
  require "libmcrdb"

  opt=Msg::GetOpts.new("tn")
  opt['v']=true
  begin
    app=App::List.new
    mdb=Mcr::Db.new('ciax')
    mcobj=Command.new
    mcobj.add_extdom(mdb,:macro).ext_mcrcmd(app,opt)
    item=mcobj.setcmd(ARGV).exe
    puts Msg.view_struct(item.record)
  rescue InvalidCMD
    opt.usage("[cmd] (par)")
  rescue UserError
    Msg.exit(3)
  ensure
  end
end
