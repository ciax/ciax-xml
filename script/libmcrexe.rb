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
      mobj=Command.new
      mobj.add_extdom(mdb,:macro)
      @mitem=mobj.setcmd(cmd)
      self['id']=cmd.first
      self
    end
  end

  class Sv < Interactive::Server
    # @<< (cobj),(output),(intgrp),interrupt,(upd_proc*)
    # @< (mdb),extdom
    # @ dryrun,aint
    attr_reader :record
    def initialize(mdb,cmd,al,opt={})
      super()
      extend(Exe).init(mdb,cmd)
      @al=Msg.type?(al,App::List)
      @opt=Msg.type?(opt,Hash)
      @record=Record.new(al,cmd.join(' '),@mitem[:label],opt)
      @upd_proc.add{
        @output=@record[:steps]
      }.upd
      @interrupt.reset_proc{|i|
        self['msg']="Interrupted"
      }
    end

    def start
      macro(@record)
      self
    rescue Quit
      self
    rescue Interlock
      self
    rescue Broken,Interrupt
      @interrupt.exe if @interrupt
      Thread.exit
      self
    end

    # Should be public for recursive call
    def macro(record,depth=1)
      @mitem.select.each{|e1|
        case record.newline(e1,depth){|aint,cmd|
            query(record,depth)
            # aint.exe(cmd)
            @interrupt=aint.interrupt
          }
        when 'done','failed','timeout'
          return
        when 'broken'
          @interrupt.exe if @interrupt
          return
        when 'run'
          puts record.crnt
        when 'mcr'
          puts record.crnt
          @index.dup.setcmd(e1['mcr']).macro(record,depth+1)
        end
      }
      self
    end

    def ext_shell
      extend(Shell).ext_shell
      self
    end

    private
    def query(record,depth)
      Thread.current[:stat]="query"
      if @opt['v']
        prompt='  '*depth+Msg.color("Proceed?[Y/N]",5)
        true while (res=Readline.readline(prompt,true)).empty?
        unless /[Yy]/ === res
          Thread.current[:stat]='broken'
          return
        end
      elsif !@opt['n']
        sleep
      end
      Thread.current[:stat]='run'
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
    mint=Mcr::Sv.new(mdb,ARGV,al,opt).start
    puts mint.record
  rescue InvalidCMD
    opt.usage("[mcr] [cmd] (par)")
  end
end
