#!/usr/bin/ruby
require "libinteractive"
require "libmcrdb"
require "libmcrcmd"
require "libapplist"

module Mcr
  module Exe
    # @< cobj,output,(intgrp),(interrupt),upd_proc*
    # @ mdb,extdom
    def init(item)
      @item=Msg.type?(item,Mcr::Cmd)
      self['id']=item.id
      self
    end
  end

  class Sv < Interactive::Server
    extend Msg::Ver
    # @<< (cobj),(output),(intgrp),interrupt,(upd_proc*)
    # @< (mdb),extdom
    # @ dryrun,aint
    attr_reader :crnt
    def initialize(item,aint,opt={})
      super()
      extend(Exe).init(item)
      @aint=Msg.type?(aint,App::List)
      @block=item.block
      @crnt=Thread.new{
        item.exe
      }
      @upd_proc.add{
        @output=@block[:record]
        self['stat']=@block[:stat]
      }.upd
      @interrupt.reset_proc{|i|
        self['msg']="Interrupted"
        @crnt.raise(Broken)
      }
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
  begin
    al=App::List.new(opt)
    mdb=Mcr::Db.new('ciax')
    mcobj=Command.new
    mcobj.add_extdom(mdb,:macro).ext_mcrcmd(al,opt)
    item=mcobj.setcmd(ARGV)
    Mcr::Sv.new(item,al,opt).ext_shell.shell
  rescue InvalidCMD
    opt.usage("[mcr] [cmd] (par)")
  end
end
