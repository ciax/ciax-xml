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
    def initialize(cobj,id,total='0')
      cobj=Msg.type?(cobj,Mcr::Command)
      update({'layer'=>'mcr','id'=>id,'total'=>total})
      super(cobj)
      stat=Stat.new
      prom=Sh::Prompt.new(self,{'total'=>"[0/%s]"})
      ext_shell(stat,prom)
    end
  end

  class List < Sh::List
    attr_reader :total
    def initialize(mdb,il)
      @il=Msg.type?(il,Ins::Layer)
      @mobj=Mcr::Command.new(mdb)
      super('0')
      @total='0'
      man=self['0']=Man.new(@mobj,mdb['id'],@total)
      @extgrp=man.cobj['sv']['ext']
      @swgrp=man.cobj['lo'].add_group('sw',"Switching Macro")
      @swgrp.add_item('0',"Macro Manager").def_proc=proc{throw(:sw_site,'0') }
      @swgrp.cmdlist["1.."]='Other Macro Process'
      @extgrp.def_proc=proc{|item|
        # item includes arbitrary mcr command
        # Sv generated and added to list in yield part as mcr command is invoked
        @total.succ!
        page="#{@total}"
        msh=self[page]=Sv.new(item,@il){|cmd,asy|
          if asy
            man.exe(cmd)
          else
            @mobj.setcmd(cmd) #submacro
          end
        }
        msh.prompt['total']="[#{page}/%s]"
        @swgrp.add_item(page).def_proc=proc{throw(:sw_site,page)}
        msh.cobj['lo']['sw']=@swgrp
        msh.cobj['lo']['ext']=@extgrp
        mexe=msh.mexe
        mexe['total']=@total
        man.output.add(page,item[:cmd],mexe)
#        man.exe([page])
      }
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
