#!/usr/bin/ruby
require "libint"
require "libmcrdb"
require "libmcrcmd"
require "libapplist"

module Mcr
  class Exe < Int::Exe
    # @< cobj,output,(intdom),(int_proc),upd_proc*
    # @ mdb,extdom
    def initialize(item)
      @item=Msg.type?(item,Mcr::Cmd)
      super()
      self['id']=item.id
    end
  end

  class Sv < Exe
    extend Msg::Ver
    # @<< (cobj),(output),(intdom),(int_proc),(upd_proc*)
    # @< (mdb),extdom
    # @ dryrun,aint
    attr_reader :crnt
    def initialize(item,aint,opt={})
      super(item)
      @aint=Msg.type?(aint,App::List)
      @block=item.block
      @crnt=Thread.new{
        item.exe
      }
      @upd_proc.add{
        @output=@block[:record]
        self['stat']=@block[:stat]
      }.upd
      @interrupt.init_proc{|i|
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
    include Int::Shell
    def ext_shell
      super({'stat' => "(%s)"})
      grp=@shdom.add_group('con','Control')
      grp.add_item('y','yes').init_proc{|i|
        if @crnt.alive?
          @crnt.run
          self['msg']="Continue"
        end
      }
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
