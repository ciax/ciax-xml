#!/usr/bin/ruby
require "libapplist"
require "libcmdext"
require "libmcrssn"

module Mcr
  module Cmd
    # @<< (index),(id*),(par*),cmd*,(def_proc*)
    # @< select*
    # @ aint,opt,interrupt
    attr_reader :session
    def self.extended(obj)
      Msg.type?(obj,Command::ExtItem)
    end

    def ext_mcrcmd(aint,session,opt={})
      @aint=Msg.type?(aint,App::List)
      @session=Msg.type?(session,Session)
      @opt=Msg.type?(opt,Hash)
      self
    end

    def exe
      @session.newline({'type'=>'mcr','mcr'=>@cmd,'label'=>self[:label]})
      @session.crnt.prt
      macro(@session)
      super
      @session.fin
      self
    rescue Interlock
      @session.fin('fail')
      self
    rescue Broken,Interrupt
      @interrupt.exe if @interrupt
      @session.fin('broken')
      Thread.exit
      self
    rescue Quit
      @session.fin('done')
      self
    end

    # Should be public for recursive call
    def macro(session,depth=1)
      session[:stat]='run'
      @select.each{|e1|
        next if session.newline(e1,depth)
        case e1['type']
        when 'exec'
          session.crnt.prt
          query(session,depth)
          @aint[e1['site']].exe(e1['cmd'])
          @interrupt=@aint[e1['site']].interrupt
        when 'mcr'
          session.crnt.prt
          @index.dup.setcmd(e1['mcr']).macro(session,depth+1)
        end
      }
      self
    end

    private
    def query(session,depth)
      session[:stat]="query"
      if @opt['v']
        prompt='  '*depth+Msg.color("Proceed?[Y/N]",5)
        true while (res=Readline.readline(prompt,true)).empty?
        raise Broken unless /[Yy]/ === res
      elsif !@opt['n']
        sleep
      end
      session[:stat]='run'
    end
  end
end

class Command::ExtDom
  def ext_mcrcmd(aint,opt={})
    values.each{|item|
      session=Mcr::Session.new(aint,opt)
      item.extend(Mcr::Cmd).ext_mcrcmd(aint,session,opt)
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
    item.session.ext_file(item.id).ext_save.save
    puts Msg.view_struct(item.session)
  rescue InvalidCMD
    opt.usage("[cmd] (par)")
  rescue UserError
    Msg.exit(3)
  ensure
  end
end
