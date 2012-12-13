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
      @record.fin
      self
    rescue Interlock
      @record.fin('fail')
    rescue Broken,Interrupt
      warn @interrupt.exe['msg']
      @record.fin('broken')
      Thread.exit
    rescue Quit
      @record.fin('done')
    ensure
      self
    end

    # Should be public for recursive call
    def macro(rec,depth=1)
      rec[:stat]='run'
      @select.each{|e1|
        next if rec.newline(e1,depth)
        case e1['type']
        when 'exec'
          rec.crnt.prt
          query(rec,depth)
          appexe(e1)
        when 'mcr'
          rec.crnt.prt
          @index.dup.setcmd(e1['mcr']).macro(rec,depth+1)
        end
      }
      self
    end

    private
    def query(rec,depth)
      rec[:stat]="query"
      if @opt['v']
        prompt='  '*depth+Msg.color("Proceed?[Y/N]",5)
        true while (res=Readline.readline(prompt,true)).empty?
        raise Broken unless /[Yy]/ === res
      elsif !@opt['n']
        sleep
      end
      rec[:stat]='run'
    end

    def appexe(db)
      exe=@exec.exe([db['site'],db['cmd']])
      @interrupt.clear.add{exe.exe(['interrupt'])}
      self
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
