#!/usr/bin/ruby
require "libmcrexe"
require "libapplist"
require "libmcrcmd"
require "thread"

module Mcr
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
