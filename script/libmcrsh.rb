#!/usr/bin/ruby
require "libint"
require "libstatus"
require "libfrmlist"
module Mcr
  class Sh < Int::Shell
    attr_reader :stat
    def initialize(citm)
      @citm=Msg.type?(citm,Command::Item)
      super(Command.new)
      @prompt['id']=mdb['id']
      @port=mdb['port'].to_i
      @stat=[]
      @prompt.table.update({'active'=>'*','wait'=>'?'})
      grp=@cobj.add_group('int',"Internal Command")
      grp.add_item("[0-9]","Switch Mode")
      grp.add_item("threads","Thread list")
      grp.add_item("list","list mcr contents")
      grp.add_item("break","[cmd|mcr] set break point")
      grp.add_item("step","step in execution")
      grp.add_item("run","run to break point")
      grp.add_item("continue","continue execution")
      grp.add_item("print","[dev:stat] print variable")
      grp.add_item("set","[dev:stat=val] set variable")
    end
  end

  class Test < Sh
    require "libsymconv"
    def initialize(mdb)
      super
      @stat.extend(Sym::Conv).load.extend(Watch::Conv)
      @post_exe << proc{@stat.upd}
      grp=@cobj.add_group('int',"Internal Command")
      cri={:type => 'reg', :list => ['.']}
      grp.add_item('set','[key=val,...]',[cri]).add_proc{|id,par|
        par.each{|exp| @stat.str_update(exp).upd}
        "Set #{par}"
      }
      self
    end

    def exe(cmd)
      @stat.set_time
      super||'OK'
    end
  end

  class Cl < Sh
    def initialize(mdb,host=nil)
      super(mdb)
      host||=mdb['host']
      @host=Msg.type?(host||mdb['host'],String)
      @stat.ext_url(@host).load
      @post_exe << proc{ @stat.load }
      extend(Int::Client)
    end
  end
end
