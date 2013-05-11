#!/usr/bin/ruby
require "libsh"
require "libmcrdb"
require "libmcrrec"
require "libcommand"
require "libinslayer"

module Mcr
  class Sv < Sh::Exe
    # @< cobj,output,(intgrp),interrupt,upd_proc*
    # @ al,appint,th,item,mobj*
    attr_accessor :mobj
    def initialize(mobj,il)
      @mobj=Msg.type?(mobj.dup,Command)
      @item=@mobj.current
      @il=Msg.type?(il,Ins::List)
      self['layer']='mcr'
      self['id']=@item.id
      record=Record.new(self)
      record.extend(Prt) unless $opt['r']
      prom=Sh::Prompt.new(self,{'stat' => "(%s)"})
      super(record,prom)
    end

    def start
      self['stat']='run'
      puts @output if Msg.fg?
      macro(@item)
      result('done')
      self
    rescue Interlock
      result('error')
      self
    rescue Interrupt
      @appint.exe if @appint
      result('interrupted')
      self
    ensure
      @output.fin
    end

    def start_bg
      @th=Thread.new{ start }
      # For shell
      @intgrp.cmdlist.valid_keys.clear
      @intgrp.add_item('e','Execute Command').reset_proc{|i| ans('e')}
      @intgrp.add_item('s','Skip Execution').reset_proc{|i| ans('s')}
      @intgrp.add_item('d','Done Macro').reset_proc{|i| ans('d')}
      @intgrp.add_item('f','Force Proceed').reset_proc{|i| ans('f')}
      @intgrp.add_item('r','Retry Checking').reset_proc{|i| ans('r')}
      @interrupt.reset_proc{|i| @th.raise(Interrupt)}
      @th
    end

    def to_s
      @mobj.current[:cmd]+'('+self['stat']+')'
    end

    private
    def macro(item,depth=1)
      item.select.each{|e1|
        begin
          @crnt=@output.add_step(e1,depth){|site|
            @il.getsh(site,'app').stat
          }
          case e1['type']
          when 'goal'
            @crnt.skip? && raise(Skip)
          when 'check'
            @crnt.fail? && raise(Interlock)
          when 'wait'
            @crnt.timeout? && raise(Interlock)
          when 'exec'
            @crnt.exec{|site,cmd,depth|
              ash=@il.getsh(site,'app')
              ash.exe(cmd)
              @appint=ash.interrupt
            }
          when 'mcr'
            puts @crnt if Msg.fg?
            macro(@mobj.setcmd(e1['cmd']),depth+1)
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
      self['stat']=str
      @output['result']=str
      puts str if Msg.fg?
    end

    def ans(str)
      return if @th.status != 'sleep'
      @th[:query]=str
      @th.run
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('rest',{'n' => 'nonstop mode','i' => 'interactive mode'})
  begin
    il=Ins::List.new('app')
    mdb=Mcr::Db.new.set('ciax')
    mobj=Command.new
    mobj.add_extdom(mdb)
    mobj.setcmd(ARGV)
    msh=Mcr::Sv.new(mobj,il)
    if $opt['i']
      msh.start
    else
      msh.start_bg
      msh.shell
    end
  rescue InvalidCMD
    $opt.usage("[mcr] [cmd] (par)")
  end
end
