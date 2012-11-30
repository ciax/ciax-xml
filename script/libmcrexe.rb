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
    def initialize(mdb,aint,logs,opt={})
      super(mdb)
      @aint=Msg.type?(aint,App::List)
      @extcmd.ext_mcrcmd(@aint,logs,opt)
      @upd_proc.add{
        if c=@cobj.current
          @output=opt['v'] ? logs.last : logs.last[:line]
          self['stat']=c[:stat]
        end
      }
    end
  end

  class List < Int::List
    # @< opt,share_proc*
    attr_reader :logs
    def initialize(opt=nil)
      @al=App::List.new(opt)
      @logs=[]
      super{|id|
        mdb=Db.new(id)
        Sv.new(mdb,@al,@logs,opt)
      }
    end

    def shell(id)
      @share_proc.add{|int|
        int.ext_shell
        grp=int.shcmd.add_group('con','Control')
        item=grp.add_item('y','yes')
        item.init_proc{|i|
          lt=@logs.last[:thread]
          lt.wakeup if lt.alive?
        }
      }
      super
    end
  end
end

if __FILE__ == $0
  opt=Msg::GetOpts.new('tvi')
  begin
    puts Mcr::List.new(opt).shell('ciax')
  rescue InvalidCMD
    opt.usage("[mcr] [cmd] (par)")
  end
end
