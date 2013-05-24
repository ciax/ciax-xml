#!/usr/bin/ruby
require "libmcrsh"

module Mcr
  class Stat < Hash
    def initialize
      @caption='<<< '+Msg.color('Active Macros',2)+' >>>'
    end

    def add(num,cmd,msh)
      self[num]=[cmd,msh]
      self
    end

    def to_s
      page=[@caption]
      each{|key,ary|
        cmd=ary[0]
        stat=ary[1]['stat']
        page << Msg.item("[#{key}]","#{cmd} (#{stat})")
      }
      page.join("\n")
    end
  end

  class Man < Sh::Exe
    def initialize(mdb,total='0')
      Msg.type?(mdb,Db)
      update({'layer'=>'mcr','id'=>mdb['id'],'total'=>total})
      stat=Stat.new
      prom=Sh::Prompt.new(self,{'total'=>"[0/%s]"})
      super(stat,prom)
      @svdom['ext']=Command::ExtGrp.new(mdb).reset_proc{|item|
        # item includes arbitrary mcr command
        # Sv generated and added to list in yield part as mcr command is invoked
        total.succ!
        num="#{total}"
        msh=yield(@cobj,num)
        msh['total']=total
        stat.add(num,item[:cmd],msh)
        raise(SelectID,num)
      }
    end
  end
end

if __FILE__ == $0
  begin
    mdb=Mcr::Db.new.set('ciax')
    man=Mcr::Man.new(mdb){puts 'OK';{}}
    true while man.shell
  rescue InvalidCMD
    $opt.usage
  end
end
