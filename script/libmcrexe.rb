#!/usr/bin/ruby
require "libinteractive"
require "libmcrdb"
require "libmcrssn"
require "libcommand"
require "libapplist"

module Mcr
  module Exe
    # @< cobj,output,(intgrp),(interrupt),upd_proc*
    # @ mdb,extdom
    def init(mdb,cmd)
      @mdb=Msg.type?(mdb,Mcr::Db)
      @cobj=Command.new
      @cobj.add_extdom(mdb,:macro)
      @select=@cobj.setcmd(cmd).select
warn @select #
      self['id']=cmd.first
      self
    end
  end

  class Sv < Interactive::Server
    # @<< (cobj),(output),(intgrp),interrupt,(upd_proc*)
    # @< (mdb),extdom
    # @ dryrun,aint
    attr_reader :crnt
    def initialize(mdb,cmd,al,opt={})
      super()
      extend(Exe).init(mdb,cmd)
      @al=Msg.type?(al,App::List)
      @opt=Msg.type?(opt,Hash)
      @session=Session.new(al,opt)
      @upd_proc.add{
        @output=@session[:record]
        self['stat']=@session[:stat]
      }.upd
      @interrupt.reset_proc{|i|
        self['msg']="Interrupted"
      }
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
          @al[e1['site']].exe(e1['cmd'])
          @interrupt=@al[e1['site']].interrupt
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

    def ext_shell
      extend(Shell).ext_shell
      self
    end
  end

  module Shell
    include Interactive::Shell
    def ext_shell
      super({'stat' => "(%s)"})
      grp=@shdom.add_group('con','Control')
      grp.add_item('y','Yes').reset_proc{|i|
        if @crnt.alive?
          @crnt.run
          self['msg']="Continue"
        end
      }
      grp.add_item('f','Force Temporaly')
      grp.add_item('r','Retry Checking')
      grp.add_item('s','Skip Execution')
      grp.add_item('i','Ignore and Memory')
    end
  end
end

if __FILE__ == $0
  opt=Msg::GetOpts.new('vti')
  opt['v']=true
  begin
    al=App::List.new(opt)
    mdb=Mcr::Db.new('ciax')
    mint=Mcr::Sv.new(mdb,ARGV,al,opt)
    mint.exe
  rescue InvalidCMD
    opt.usage("[mcr] [cmd] (par)")
  end
end
