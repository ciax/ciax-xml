#!/usr/bin/ruby
require "libmcrdb"
require "libmcrrec"
require "libcommand"
require "libinssh"

module CIAX
  module Mcr
    class Exe < Sh::Exe
      attr_reader :record
      def initialize(mitem,alist,&mcr_proc)
        super(Command.new)
        @mitem=type?(mitem,Item)
        @alist=type?(alist,App::List)
        @record=Record.new(@mitem.cmd,@mitem[:label],self)
        @record.extend(Prt) unless $opt['r']
        self['layer']='mcr'
        self['id']=@mitem[:cmd]
        # @mcr_proc{|cmd,async?(t/f)|} for submacro
        @mcr_proc=mcr_proc
      end

      def start # separated for sub thread
        self['stat']='run'
        puts @record if Msg.fg?
        macro(@mitem)
        result('done')
        self
      rescue Interlock
        result('error')
        self
      rescue Interrupt
        @appint.call if @appint
        result('interrupted')
        self
      ensure
        @record.fin
      end

      def to_s
        @mitem[:cmd]+'('+self['stat']+')'
      end

      private
      def macro(item,depth=1)
        item.select.each{|e1|
          begin
            step=@record.add_step(e1,depth){|site|
              @alist[site].stat
            }
            case e1['type']
            when 'goal'
              res= step.skip? && !step.dryrun?
              puts step if Msg.fg?
              raise(Skip) if res
            when 'check'
              res=step.fail?
              puts step if Msg.fg?
              raise(Interlock) if res && step.done?
            when 'wait'
              print step.title if Msg.fg?
              max=step.dryrun? ? 3 : nil
              res=step.timeout?(max){ print '.' if Msg.fg?}
              puts step.result if Msg.fg?
              raise(Interlock) if res && step.done?
            when 'exec'
              puts step.title if Msg.fg?
              step.exec(step.exec?){|site,cmd,depth|
                ash=@alist[site]
                ash.exe(cmd)
                @appint=ash.cobj['sv']['hid']['interrupt']
              }
              puts step.action if Msg.fg?
            when 'mcr'
              puts step if Msg.fg?
              item=@mcr_proc.call(e1['cmd'],/true|1/ === e1['async'])
              macro(item,depth+1) if item.is_a? Item
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
        @record['result']=str
        puts str if Msg.fg?
      end
    end
  end

  if __FILE__ == $0
    GetOpts.new('rest',{'n' => 'nonstop mode'})
    begin
      al=App::List.new
      mdb=Mcr::Db.new.set('ciax')
      mobj=ExtCmd.new(mdb)
      mitem=mobj.setcmd(ARGV)
      msh=Mcr::Exe.new(mitem,al){|cmd,asy|
        mobj.setcmd(cmd) unless asy
      }
      msh.start
    rescue InvalidCMD
      $opt.usage("[mcr] [cmd] (par)")
    end
  end
end
