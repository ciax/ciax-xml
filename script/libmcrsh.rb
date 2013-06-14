#!/usr/bin/ruby
require "libmcrexe"

module CIAX
  module Mcr
    class Sv < Exe
      # @< cobj,output,upd_proc*
      # @ al,appint,th,item,mobj*
      attr_reader :prompt,:th
      def initialize(mitem,il,&mcr_proc)
        super(mitem,il,&mcr_proc)
        @il=Msg.type?(il,Ins::Layer)
        @cobj=Command.new
        @upd_proc=UpdProc.new
        prom=Sh::Prompt.new(self,{'stat' => "(%s)"})
        ext_shell(@record,prom)
        ig=@cobj['sv']['int']
        ig.add_item('e','Execute Command').def_proc=proc{ ans('e') }
        ig.add_item('s','Skip Execution').def_proc=proc{ ans('s') }
        ig.add_item('d','Done Macro').def_proc=proc{ ans('d') }
        ig.add_item('f','Force Proceed').def_proc=proc{ ans('f') }
        ig.add_item('r','Retry Checking').def_proc=proc{ ans('r') }
        @th=Thread.new(ig.valid_keys.clear){|vk| start(vk) }
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
      mobj=ExtCmd.new(mdb)
      mitem=mobj.setcmd(ARGV)
      msh=Mcr::Sv.new(mitem,il){|cmd,asy|
        mobj.setcmd(cmd) unless asy
      }
      msh.shell
    rescue InvalidCMD
      $opt.usage("[mcr] [cmd] (par)")
    end
  end
end
