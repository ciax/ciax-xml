#!/usr/bin/ruby
require "libint"
require "libmcrdb"
require "libmcrcmd"
require "libapplist"

module Mcr
  class Exe < Int::Exe
    # @< cobj,output,(intcmd),(int_proc),upd_proc*
    # @ mdb,extcmd
    def initialize(mdb)
      @mdb=Msg.type?(mdb,Mcr::Db)
      super()
      self['id']=@mdb['id']
      @extcmd=@cobj.add_ext(@mdb,:macro)
    end
  end

  class Sv < Exe
    extend Msg::Ver
    # @<< (cobj),(output),(intcmd),(int_proc),(upd_proc*)
    # @< (mdb),extcmd
    # @ dryrun,aint
    def initialize(mdb,aint,opt={})
      super(mdb)
      @aint=Msg.type?(aint,App::List)
      @extcmd.ext_mcrcmd(@aint,opt)
      @upd_proc.add{
        if c=@cobj.current
          @output=opt['v'] ? c.logline : c.logline[:line]
          self['stat']=c[:msg]
        end
      }
    end
  end

  class List < Int::List
    # @< opt,share_proc*
    def initialize(opt=nil)
      @al=App::List.new(opt)
      super{|id|
        mdb=Db.new(id)
        Sv.new(mdb,@al,opt).ext_shell
      }
    end
  end
end

if __FILE__ == $0
  opt=Msg::GetOpts.new('tvi')
  begin
    puts Mcr::List.new(opt)[ARGV.shift].shell
  rescue InvalidCMD
    opt.usage("[mcr] [cmd] (par)")
  end
end
