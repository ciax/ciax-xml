#!/usr/bin/ruby
require "libmcrexe"

module Mcr
  class Sv < Sh::Exe
    # @< cobj,output,upd_proc*
    # @ al,appint,th,item,mobj*
    attr_reader :mexe,:prompt,:th
    def initialize(mitem,mobj,il)
      @mobj=Msg.type?(mobj.dup,Command)
      @il=Msg.type?(il,Ins::Layer)
      cobj=Command.new
      @mitem=Msg.type?(mitem,Command::Item)
      @mexe=Exe.new(@mitem,mobj,il)
      prom=Sh::Prompt.new(@mexe,{'stat' => "(%s)"})
      super(cobj,@mexe.record,prom)
      ig=@cobj['sv']['int']
      ig.add_item('e','Execute Command').def_proc=proc{ ans('e') }
      ig.add_item('s','Skip Execution').def_proc=proc{ ans('s') }
      ig.add_item('d','Done Macro').def_proc=proc{ ans('d') }
      ig.add_item('f','Force Proceed').def_proc=proc{ ans('f') }
      ig.add_item('r','Retry Checking').def_proc=proc{ ans('r') }
      @th=Thread.new(ig.valid_keys.clear){|vk| @mexe.start(vk) }
      @cobj.int_proc=proc{|i| @th.raise(Interrupt)}
      @th
    end

    def ans(str)
      return if @th.status != 'sleep'
      @th[:query]=str
      @th.run
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('rest',{'n' => 'nonstop mode'})
  begin
    il=Ins::Layer.new('app')
    mdb=Mcr::Db.new.set('ciax')
    mobj=Mcr::Command.new(mdb)
    mitem=mobj.setcmd(ARGV)
    msh=Mcr::Sv.new(mitem,mobj,il)
    msh.shell
  rescue InvalidCMD
    $opt.usage("[mcr] [cmd] (par)")
  end
end
