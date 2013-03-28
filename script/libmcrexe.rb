#!/usr/bin/ruby
require "libinteractive"
require "libmcrdb"
require "libmcrrec"
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
warn self
      @al=Msg.type?(al,App::List)
      @opt=Msg.type?(opt,Hash)
      @record=Record.new(al,opt)
      @record.newline({'type'=>'mcr','mcr'=>cmd,'label'=>self[:label]})
      @upd_proc.add{
        @output=@record[:steps]
        self['stat']=@record[:stat]
      }.upd
      @interrupt.reset_proc{|i|
        self['msg']="Interrupted"
      }
    end

    def exe
      @record.crnt.prt
      macro(@record)
      @record.fin
      self
    rescue Interlock
      @record.fin('fail')
      self
    rescue Broken,Interrupt
      @interrupt.exe if @interrupt
      @record.fin('broken')
      Thread.exit
      self
    rescue Quit
      @record.fin('done')
      self
    end

    # Should be public for recursive call
    def macro(record,depth=1)
      record[:stat]='run'
      @select.each{|e1|
        next if record.newline(e1,depth)
        case e1['type']
        when 'exec'
          record.crnt.prt
          query(record,depth)
          @al[e1['site']].exe(e1['cmd'])
          @interrupt=@al[e1['site']].interrupt
        when 'mcr'
          record.crnt.prt
          @index.dup.setcmd(e1['mcr']).macro(record,depth+1)
        end
      }
      self
    end

    private
    def query(record,depth)
      record[:stat]="query"
      if @opt['v']
        prompt='  '*depth+Msg.color("Proceed?[Y/N]",5)
        true while (res=Readline.readline(prompt,true)).empty?
        raise Broken unless /[Yy]/ === res
      elsif !@opt['n']
        sleep
      end
      record[:stat]='run'
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
