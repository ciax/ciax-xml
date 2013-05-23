#!/usr/bin/ruby
require "libmcrsh"

module Mcr
  class Man < Sh::Exe
    def initialize(mdb,total='0')
      Msg.type?(mdb,Db)
      update({'layer'=>'mcr','id'=>mdb['id'],'total'=>total})
      stat=Msg::CmdList.new('caption'=>'Active Macros','color'=>2,'show_all'=>true)
      prom=Sh::Prompt.new(self,{'total'=>"[0/%s]"})
      super(stat,prom)
      @svdom.add_extgrp(mdb).reset_proc{|item|
        # item includes arbitrary mcr command
        # Sv generated and added to list in yield part as mcr command is invoked
        total.succ!
        num="#{total}"
        msh=yield(@cobj,num)
        msh['total']=total
        stat["[#{num}]"]="#{item[:cmd]} (#{msh['stat']})"
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
