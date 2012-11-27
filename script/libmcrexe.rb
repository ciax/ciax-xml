#!/usr/bin/ruby
require "libint"
require "libstatus"
require "libapplist"
require "libmcrcmd"
require "thread"

module Mcr
  class Exe < Int::Exe
    # @< cobj,(output),(intcmd),(int_proc),(upd_proc*)
    # @ mdb,extcmd,logline*
    attr_reader :logline
    def initialize(mdb)
      @mdb=Msg.type?(mdb,Mcr::Db)
      super()
      self['id']=@mdb['id']
      @extcmd=@cobj.add_ext(@mdb,:macro)
      @logline=ExHash.new
    end

    def ext_shell
      super({'active'=>'*','wait'=>'?'})
      grp=@shcmd.add_group('int',"Internal Command")
      grp.add_item("[0-9]","Switch Mode")
      grp.add_item("threads","Thread list")
      grp.add_item("list","list mcr contents")
      grp.add_item("break","[cmd|mcr] set break point")
      grp.add_item("step","step in execution")
      grp.add_item("run","run to break point")
      grp.add_item("continue","continue execution")
      grp.add_item("print","[dev:stat] print variable")
      grp.add_item("set","[dev:stat=val] set variable")
      self
    end
  end

  class Sv < Exe
    extend Msg::Ver
    # @<< cobj,output,intcmd,int_proc,upd_proc*
    # @< mdb,extcmd,logline*
    # @ dryrun,aint
    def initialize(mdb,aint,dr=nil)
      super(mdb)
      @aint=Msg.type?(aint,App::List)
      @extcmd.ext_mcrcmd(@aint,@logline,dr)
    end
  end
end

if __FILE__ == $0
  require "libmcrdb"
#  ENV['VER']='appsv'

  opt=Msg::GetOpts.new("t")
  id,*cmd=ARGV
  ARGV.clear
  begin
    aint=App::List.new
    mdb=Mcr::Db.new(id) #ciax
    mcr=Mcr::Sv.new(mdb,aint,opt['t'])
    mcr.ext_shell.shell
  rescue InvalidCMD
    Msg.exit(2)
  rescue InvalidID
    opt.usage("[mcr] [cmd] (par)")
  rescue UserError
    Msg.exit(3)
  end
end
