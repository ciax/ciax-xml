#!/usr/bin/ruby
require "libint"
require "libmcrdb"

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
      @upd_proc.add{
        @output=@logline
      }
    end
  end

  class Sv < Exe
    require "libapplist"
    require "libmcrcmd"
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
