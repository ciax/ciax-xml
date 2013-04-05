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
      @record.extend(Prt) if $opt['v']
      @record.stat_proc=proc{|site| @al[site].stat }
      @record.exe_proc=proc{|site,cmd,depth|
        query(depth)
        aint=@al[site]
        aint.exe(cmd)
        @interrupt=aint.interrupt
      }
      self
    end

    def exe
      self['stat']="run"
      puts @record if Msg.fg?
      macro(@item)
      self
    rescue Quit
      self
    rescue Interrupt
      @interrupt.exe if @interrupt
      self
    end

    private
    def macro(item,depth=1)
      Msg.type?(item,Command::Item).select.each{|e1|
        self['stat']="wait"
        begin
          if mcr=@record.nextstep(e1,depth)
            macro(@cobj.setcmd(mcr),depth+1)
          end
        rescue Interlock
          query(depth)
        end
      }
      self
    end

    def query(depth)
      self['stat']="query"
      if Msg.fg?
        prompt='  '*depth+Msg.color("Proceed?[Y/N]",5)
        true while (res=Readline.readline(prompt,true)).empty?
        unless /[Yy]/ === res
          self['stat']='broken'
          raise(Quit)
        end
      elsif !$opt['n']
        sleep
      end
      self['stat']='run'
    end
  end

  class Shell < Interactive::Server
    # @< cobj,output,intgrp,interrupt,upd_proc*
    # @ mint
    include Interactive::Shell
    def initialize(mdb,al)
      @mint=Sv.new(mdb,al)
      super()
      ext_shell({'stat' => "(%s)"},@mint)
      @intgrp.add_item('y','Yes').reset_proc{|i|
        if @th.alive?
          @th.run
          self['msg']="Continue"
        end
      }
      @intgrp.add_item('f','Force Temporaly')
      @intgrp.add_item('r','Retry Checking')
      @intgrp.add_item('s','Skip Execution')
      @intgrp.add_item('i','Ignore and Memory')
    end

    def shell(cmd)
      @output=@mint.setcmd(cmd).record
      @th=Thread.new{ @mint.exe }
      super()
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('vst')
  begin
    al=App::List.new
    mdb=Mcr::Db.new('ciax')
#    mint=Mcr::Sv.new(mdb,al)
#    mint.setcmd(ARGV)
#    mint.exe
    mint=Mcr::Shell.new(mdb,al)
    mint.shell(ARGV)
  rescue InvalidCMD
    $opt.usage("[mcr] [cmd] (par)")
  end
end
