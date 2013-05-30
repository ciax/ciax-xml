#!/usr/bin/ruby
require "libsh"
require "libmcrdb"
require "libmcrrec"
require "libcommand"
require "libinssh"

module Mcr
  class Sv < Sh::Exe
    # @< cobj,output,upd_proc*
    # @ al,appint,th,item,mobj*
    attr_accessor :mobj,:prompt
    attr_reader :intgrp
    def initialize(mobj,il)
      @mobj=Msg.type?(mobj.dup,Command)
      @il=Msg.type?(il,Ins::Layer)
      record=Record.new(self)
      record.extend(Prt) unless $opt['r']
      @mitem=@mobj.current
      self['layer']='mcr'
      self['id']=@mitem[:cmd]
      prom=Sh::Prompt.new(self,{'stat' => "(%s)"})
      super(record,prom)
      @intgrp=@svdom.add_group('int',"Internal Command")
    end

    def start
      self['stat']='run'
      puts @output if Msg.fg?
      macro(@mitem)
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
      # For shell
      @interrupt.def_proc=proc{|i| @th.raise(Interrupt)}
      @intgrp.add_item('e','Execute Command').def_proc=proc{ ans('e') }
      @intgrp.add_item('s','Skip Execution').def_proc=proc{ ans('s') }
      @intgrp.add_item('d','Done Macro').def_proc=proc{ ans('d') }
      @intgrp.add_item('f','Force Proceed').def_proc=proc{ ans('f') }
      @intgrp.add_item('r','Retry Checking').def_proc=proc{ ans('r') }
      @intgrp.valid_keys.clear
      @th=Thread.new{ start }
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
            @il['app'][site].stat
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
              ash=@il['app'][site]
              ash.exe(cmd)
              @appint=ash.interrupt
            }
          when 'mcr'
            puts @crnt if Msg.fg?
            Msg.warn('Async') if /true|1/ === e1['async']
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
    il=Ins::Layer.new('app')
    mdb=Mcr::Db.new.set('ciax')
    mobj=Command.new
    svdom=mobj.add_domain('sv',6)
    svdom['ext']=Command::ExtGrp.new(mdb)
    mitem=mobj.setcmd(ARGV)
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
