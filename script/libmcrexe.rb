#!/usr/bin/ruby
require "libint"
require "libmcrdb"
require "libmcrcmd"
require "libapplist"

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

  class List < Int::List
    # @< opt,share_proc*
    def initialize(opt=nil)
      @al=App::List.new(opt)
      super{|id|
        mdb=Db.new(id)
        Sv.new(mdb,@al,@opt['t']).ext_shell
      }
    end
  end
end

if __FILE__ == $0
  opt=Msg::GetOpts.new('t')
  begin
    puts Mcr::List.new(opt)[ARGV.shift].shell
  rescue InvalidCMD
    opt.usage("[mcr] [cmd] (par)")
  end
end
