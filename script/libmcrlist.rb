#!/usr/bin/ruby
require "libmcrman"

module Mcr
  class List < Sh::List
    attr_reader :total
    def initialize(mdb,il)
      @il=Msg.type?(il,Ins::Layer)
      super('0')
      @total='0'
      man=self['0']=Man.new(mdb,@total){|mobj,num| newmcr(mobj,num)}
      @swgrp=man.lodom.add_group('sw',"Switching Macros")
      @swgrp.add_item('0',"Macro Manager").reset_proc{throw(:sw_site,'0') }
      @swgrp.cmdlist["1.."]='Other Macro Process'
    end

    def newmcr(mobj,num)
      msh=self[num]=Sv.new(mobj,@il)
      msh.prompt['total']="[#{num}/%s]"
      msh.lodom['sw']=@swgrp
      @swgrp.add_item(num).reset_proc{throw(:sw_site,num)}
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
    $opt.usage("[mcr] [cmd] (par)")
  end
end
