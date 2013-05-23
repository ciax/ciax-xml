#!/usr/bin/ruby
require "libmcrsh"

module Mcr
  class Man < Sh::Exe
    def initialize(mdb,total='0',&post_proc)
      Msg.type?(mdb,Db)
      update({'layer'=>'mcr','id'=>mdb['id'],'total'=>total})
      stat=Msg::CmdList.new('caption'=>'Active Macros','color'=>2,'show_all'=>true)
      prom=Sh::Prompt.new(self,{'total'=>"[0/%s]"})
      super(stat,prom)
      @svdom.add_extgrp(mdb).reset_proc{|item|
        # item includes arbitrary mcr command
        # Sv generated and added to list in yield part as mcr command is invoked
        total.succ!
        msh=newmcr
        msh['total']=total
        stat["[#{total}]"]="#{item[:cmd]} (#{msh['stat']})"
        post_proc.call(total) if post_proc
      }
    end

    private
    def newmcr
      {}
    end
  end
end

if __FILE__ == $0
  begin
    mdb=Mcr::Db.new.set('ciax')
    man=Mcr::Man.new(mdb)
    man.shell
  rescue InvalidCMD
    $opt.usage
  end
end
