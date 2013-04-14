#!/usr/bin/ruby
require "libinteractive"
require "libmcrdb"
require "libmcrrec"
require "libcommand"
require "libapplist"

module Mcr
  class Sv < Interactive::Server
    # @< cobj,output,(intgrp),interrupt,upd_proc*
    # @ al,item,record*
    attr_reader :record
    def initialize(item,al)
      @item=Msg.type?(item,Command::Item)
      self['id']=@item.id
      record=Record.new(@item)
      record.extend(Prt) unless $opt['r']
      record.stat_proc=proc{|site| al[site].stat }
      record.exe_proc=proc{|site,cmd,depth|
        aint=al[site]
        aint.exe(cmd)
        @interrupt=aint.interrupt
      }
      super(record)
      @output=record
      @interrupt.reset_proc{|i|
        self['msg']="Interrupted"
      }
    end

    def macro
      self['stat']='run'
      puts @output if Msg.fg?
      @output.macro(@item)
      result('done')
      self
    rescue Interlock
      result('error')
      self
    rescue Interrupt
      @interrupt.exe if @interrupt
      result('interrupted')
      self
    end

    def result(str)
      self['stat']=str
      @output['result']=str
    end

    def ext_shell
      extend(Shell).ext_shell
    end

  end

  module Shell
    include Interactive::Shell
    def self.extended(obj)
      Msg.type?(obj,Sv)
    end

    def ext_shell
      super({'stat' => "(%s)"})
      @intgrp.add_item('e','Execute Command').reset_proc{|i| ans('e')}
      @intgrp.add_item('s','Skip Execution').reset_proc{|i| ans('s')}
      @intgrp.add_item('d','Done Macro').reset_proc{|i| ans('d')}
      @intgrp.add_item('f','Force Proceed').reset_proc{|i| ans('f')}
      @intgrp.add_item('r','Retry Checking').reset_proc{|i| ans('r')}
      self
    end

    def shell
      @th=Thread.new{ macro }
      super()
    end

    private
    def ans(str)
      return if @th.status != 'sleep'
      @output.crnt[:query]=str
      @th.run
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('rest',{'n' => 'nonstop mode','i' => 'interactive mode'})
  begin
    al=App::List.new
    mdb=Mcr::Db.new('ciax')
    mobj=Command.new
    mobj.add_extdom(mdb,:macro)
    mitem=mobj.setcmd(ARGV)
    mint=Mcr::Sv.new(mitem,al)
    if $opt['i']
      mint.macro
    else
      mint.ext_shell
      mint.shell
    end
  rescue InvalidCMD
    $opt.usage("[mcr] [cmd] (par)")
  end
end
