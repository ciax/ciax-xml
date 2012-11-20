#!/usr/bin/ruby
require "libmcrexe"
require "libapplist"
require "libmcrcmd"
require "thread"

module Mcr
  class Sv < Exe
    extend Msg::Ver
    #@<< cobj,output,intcmd,int_proc,upd_proc*
    #@< mdb,extcmd,logline*
    #@ dryrun,aint
    def initialize(mdb,aint,dr=nil)
      super(mdb)
      @dryrun=dr
      @aint=Msg.type?(aint,App::List)
      @cobj.values.each{|item|
        item.extend(Mcr::Cmd)
      }
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
    app=App::List.new
    mdb=Mcr::Db.new(id) #ciax
    mcr=Mcr::Sv.new(mdb,app,opt['t'])
    puts mcr.exe(cmd)
    puts mcr[:stat]
  rescue InvalidCMD
    Msg.exit(2)
  rescue InvalidID
    opt.usage("[mcr] [cmd] (par)")
  rescue UserError
    Msg.exit(3)
  end
end
