#!/usr/bin/ruby
require "libint"
require "libstatus"

module Mcr
  class Exe < Int::Exe
    attr_reader :logline
    def initialize(mdb)
      @mdb=Msg.type?(mdb,Mcr::Db)
      super()
      @extcmd=@cobj.add_ext(@mdb,:macro)
      @logline=[]
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

  class Test < Exe
    require "libsymconv"
    def initialize(mdb)
      super
      @stat.extend(Sym::Conv).load.extend(Watch::Conv)
      grp=@intcmd.add_group('int',"Internal Command")
      cri={:type => 'reg', :list => ['.']}
      grp.add_item('set','[key=val,...]',[cri]).init_proc{|item|
        item.par.each{|exp| @stat.str_update(exp).upd}
        "Set #{item.par}"
      }
      self
    end

    def exe(cmd)
      @stat.set_time
      super||'OK'
    end

    def upd
      super
      @stat.upd
      self
    end
  end

  class Cl < Exe
    def initialize(mdb,host=nil)
      super(mdb)
      host||=mdb['host']
      host=Msg.type?(host||mdb['host'],String)
      @stat.ext_url(host).load
      ext_client(host,mdb['port'])
    end

    def upd
      super
      @stat.load
      self
    end
  end
end
