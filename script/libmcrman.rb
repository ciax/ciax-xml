#!/usr/bin/ruby
require "libmcrsh"

module Mcr
  class Man < Sh::Exe
    # @< cobj,output,(intgrp),interrupt,upd_proc*
    def initialize(mdb,il)
      @mdb=Msg.type?(mdb,Db)
      self['layer']='mcr'
      self['id']=@mdb['id']
      prom=Sh::Prompt.new(self)
      super({},prom)
      @extdom=@cobj.add_extdom(@mdb)
      @extdom.reset_proc{|item|
        Mcr::Sv.new(@cobj,il).shell
      }
    end
  end
end

if __FILE__ == $0
  begin
    il=Ins::List.new('app')
    mdb=Mcr::Db.new('ciax')
    man=Mcr::Man.new(mdb,il)
    man.shell
  rescue InvalidCMD
    $opt.usage("[mcr] [cmd] (par)")
  end
end
