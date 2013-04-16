#!/usr/bin/ruby
require "libinteractive"
require "libmcrdb"
require "libmcrrec"
require "libcommand"
require "libapplist"

module Mcr
  class Sv < Interactive::Server
    # @< cobj,output,(intgrp),interrupt,upd_proc*
    # @ al,mobj*
    attr_accessor :mobj
    def initialize(mobj,al)
      @mobj=Msg.type?(mobj,Command)
      @al=Msg.type?(al,App::List)
      self['id']=@mobj.current.id
      record=Record.new(self)
      record.extend(Prt) unless $opt['r']
      super(record)
      @interrupt.reset_proc{|i|
        self['msg']="Interrupted"
      }
    end

    def start
      self['stat']='run'
      puts @output if Msg.fg?
      macro(@mobj.current)
      result('done')
      self
    rescue Interlock
      result('error')
      self
    rescue Interrupt
      @interrupt.exe if @interrupt
      result('interrupted')
      self
    ensure
      @output.fin
    end

    def ext_shell
      extend(Shell).ext_shell
    end

    private
    def macro(item,depth=1)
      item.select.each{|e1|
        begin
          @crnt=@output.add_step(e1,depth){|site|
            @al[site].stat
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
              aint=@al[site]
              aint.exe(cmd)
              @interrupt=aint.interrupt
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
      @th=Thread.new{ start }
      super()
    end

    private
    def ans(str)
      return if @th.status != 'sleep'
      @crnt[:query]=str
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
    mobj.setcmd(ARGV)
    mint=Mcr::Sv.new(mobj,al)
    if $opt['i']
      mint.start
    else
      mint.ext_shell
      mint.shell
    end
  rescue InvalidCMD
    $opt.usage("[mcr] [cmd] (par)")
  end
end
