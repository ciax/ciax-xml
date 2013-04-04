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
    def init(mdb)
      @mdb=Msg.type?(mdb,Mcr::Db)
      @mobj=Command.new
      @mobj.add_extdom(mdb,:macro)
      self
    end
  end

  class Sv < Interactive::Server
    # @<< (cobj),(output),(intgrp),interrupt,(upd_proc*)
    # @< (mdb),extdom
    # @ dryrun,aint
    attr_reader :record
    def initialize(mdb,al,opt={})
      super()
      extend(Exe).init(mdb)
      @al=Msg.type?(al,App::List)
      @opt=Msg.type?(opt,Hash)
      @record=Record.new(al,opt)
      @upd_proc.add{
        @output=@record[:steps]
      }.upd
      @interrupt.reset_proc{|i|
        self['msg']="Interrupted"
      }
      Thread.current[:stat]="ready"
    end

    def start(cmd)
      Thread.current[:stat]="run"
      self['id']=cmd.first
      mitem=@mobj.setcmd(cmd)
      @record[:mcr]=cmd.join(' ')
      @record[:label]=mitem[:label]
      macro(cmd)
      self
    rescue Quit
      self
    rescue Interrupt
      @interrupt.exe if @interrupt
      self
    end

    # Should be public for recursive call
    def macro(cmd,depth=1)
      @mobj.setcmd(cmd).select.each{|e1|
        Thread.current[:stat]="wait"
        if res=@record.newline(e1,depth)
          case res
          when 'mcr'
            macro(e1['mcr'],depth+1)
          when Array
            query(depth)
            # aint.exe(cmd)
            # @interrupt=aint.interrupt
          end
        else
          query(depth)
        end
      }
      self
    end

    def ext_shell
      extend(Shell).ext_shell
      self
    end

    private
    def query(depth)
      Thread.current[:stat]="query"
      if @opt['v']
        prompt='  '*depth+Msg.color("Proceed?[Y/N]",5)
        true while (res=Readline.readline(prompt,true)).empty?
        unless /[Yy]/ === res
          Thread.current[:stat]='broken'
          raise(Quit)
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
    mint=Mcr::Sv.new(mdb,al,opt)
    mint.start(ARGV)
    puts mint.record
  rescue InvalidCMD
    opt.usage("[mcr] [cmd] (par)")
  end
end
