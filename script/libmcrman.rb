#!/usr/bin/ruby
require "libmcrsh"

module Mcr
  class Stat < Hash
    def initialize
      @caption='<<< '+Msg.color('Active Macros',2)+' >>>'
    end

    def add(num,cmd,mexe)
      self[num]=[cmd,mexe]
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
      ext=@svdom['ext']=Command::ExtGrp.new(mdb)
      ext.def_proc=proc{|item|
        # item includes arbitrary mcr command
        # Sv generated and added to list in yield part as mcr command is invoked
        total.succ!
        num="#{total}"
        mexe=yield(@cobj,num)
        mexe['total']=total
        stat.add(num,item[:cmd],mexe)
      }
    end
  end

  class List < Sh::List
    attr_reader :total
    def initialize(mdb,il)
      @il=Msg.type?(il,Ins::Layer)
      super('0')
      @total='0'
      man=self['0']=Man.new(mdb,@total){|mobj,num| newmcr(mobj,num)}
      @swgrp=man.lodom.add_group('sw',"Switching Macros")
      @swgrp.add_item('0',"Macro Manager").def_proc=proc{throw(:sw_site,'0') }
      @swgrp.cmdlist["1.."]='Other Macro Process'
    end

    def newmcr(mobj,num)
      msh=self[num]=Sv.new(mobj,@il)
      msh.prompt['total']="[#{num}/%s]"
      msh.lodom['sw']=@swgrp
      @swgrp.add_item(num).def_proc=proc{throw(:sw_site,num)}
      msh.mexe
    end
  end
end

if __FILE__ == $0
  begin
    il=Ins::Layer.new('mcr')
    mdb=Mcr::Db.new.set('ciax')
    man=Mcr::List.new(mdb,il)
    man.shell
  rescue InvalidCMD
    $opt.usage
  end
end
