#!/usr/bin/ruby
require "libmcrexe"

module Mcr
  class Sv < Sh::Exe
    # @< cobj,output,upd_proc*
    # @ al,appint,th,item,mobj*
    attr_accessor :mobj,:prompt
    attr_reader :intgrp,:th
    def initialize(mobj,il)
      @mobj=Msg.type?(mobj.dup,Command)
      @il=Msg.type?(il,Ins::Layer)
      @mitem=@mobj.current
      @exe=Exe.new(@mitem,mobj,il)
      prom=Sh::Prompt.new(@exe,{'stat' => "(%s)"})
      super(@exe.record,prom)
      @intgrp=@svdom.add_group('int',"Internal Command")
      @intgrp.add_item('e','Execute Command').reset_proc{ ans('e') }
      @intgrp.add_item('s','Skip Execution').reset_proc{ ans('s') }
      @intgrp.add_item('d','Done Macro').reset_proc{ ans('d') }
      @intgrp.add_item('f','Force Proceed').reset_proc{ ans('f') }
      @intgrp.add_item('r','Retry Checking').reset_proc{ ans('r') }
      @th=Thread.new(@intgrp.valid_keys.clear){|vk| @exe.start(vk) }
      @interrupt.reset_proc{|i| @th.raise(Interrupt)}
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
    mobj=Command.new
    svdom=mobj.add_domain('sv',6)
    svdom['ext']=Command::ExtGrp.new(mdb)
    mitem=mobj.setcmd(ARGV)
    msh=Mcr::Sv.new(mobj,il)
    msh.shell
  rescue InvalidCMD
    $opt.usage("[mcr] [cmd] (par)")
  end
end
