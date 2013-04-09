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
    def initialize(mdb,al)
      Msg.type?(mdb,Mcr::Db)
      super()
      @cobj.add_extdom(mdb,:macro)
      @al=Msg.type?(al,App::List)
      @record={}
      @interrupt.reset_proc{|i|
        self['msg']="Interrupted"
      }
    end

    def setcmd(cmd)
      self['id']=cmd.first
      @item=@cobj.setcmd(cmd)
      @record=Record.new(cmd,@item[:label])
      @record.extend(Prt) unless $opt['r']
      @record.stat_proc=proc{|site| @al[site].stat }
      @record.exe_proc=proc{|site,cmd,depth|
        aint=@al[site]
        aint.exe(cmd)
        @interrupt=aint.interrupt
      }
      self
    end

    def exe
      self['msg']='run'
      puts @record if Msg.fg?
      macro(@item)
      result('done')
      self
    rescue Quit
      self
    rescue Interlock
      result('error')
      self
    rescue Interrupt
      @interrupt.exe if @interrupt
      result('interrupted')
      self
    end

    private
    def macro(item,depth=1)
      Msg.type?(item,Command::Item).select.each{|e1|
        self['msg']="wait"
        begin
          if mcr=@record.nextstep(e1,depth)
            macro(@cobj.setcmd(mcr),depth+1)
          end
        rescue Retry
          retry
        rescue Skip
          return
        end
      }
      self
    end

    def result(str)
      self['msg']=str
      @record['result']=str
    end
  end

  class Shell < Interactive::Server
    # @< cobj,output,intgrp,interrupt,upd_proc*
    # @ mint
    include Interactive::Shell
    def initialize(mdb,al)
      @mint=Sv.new(mdb,al)
      super()
      ext_shell({'msg' => "(%s)"},@mint)
      @intgrp.add_item('y','Yes').reset_proc{|i|
        if @th.alive?
          @th.run
          self['msg']="Continue"
        end
      }
      @intgrp.add_item('f','Force Temporaly').reset_proc{|i| @th.run }
      @intgrp.add_item('r','Retry Checking').reset_proc{|i| @th.raise(Retry)}
      @intgrp.add_item('s','Skip Execution').reset_proc{|i| @th.raise(Retry)}
      @intgrp.add_item('q','Quit Execution').reset_proc{|i| @th.raise(Quit) }
    end

    def shell(cmd)
      @output=@mint.setcmd(cmd).record
      @th=Thread.new{ @mint.exe }
      super()
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('rest',{'n' => 'nonstop mode','i' => 'interactive mode'})
  begin
    al=App::List.new
    mdb=Mcr::Db.new('ciax')
    if $opt['i']
      mint=Mcr::Sv.new(mdb,al)
      mint.setcmd(ARGV)
      mint.exe
    else
      mint=Mcr::Shell.new(mdb,al)
      mint.shell(ARGV)
    end
  rescue InvalidCMD
    $opt.usage("[mcr] [cmd] (par)")
  end
end
