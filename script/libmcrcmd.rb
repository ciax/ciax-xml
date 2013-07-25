#!/usr/bin/ruby
require "libmcrdb"
require "libmcrrec"
require "libcommand"
require "libinssh"

module CIAX
  module Mcr
    class ExtCmd < ExtCmd
      attr_reader :record
      def initialize(mdb,alist,sh={:valid_keys =>[]},&mcr_proc)
        super(mdb)
        @sh=type?(sh,Hash)
        @alist=type?(alist,App::List)
        self['sv']['ext'].def_proc=proc{|mitem| start(mitem)}
        @mcr_proc=mcr_proc
      end

      def start(mitem) # separated for sub thread
        @mitem=type?(mitem,Item)
        @sh['stat']='run'
        @record=Record.new(@mitem.cmd,@mitem[:label],@sh)
        @record.extend(Prt) unless $opt['r']
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
              item=setcmd(e1['cmd'])
              if /true|1/ === e1['async']
                @mcr_proc.call(item)
              else
                macro(item,depth+1)
              end
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
        @sh['stat']=str
        @record['result']=str
        puts str if Msg.fg?
      end
    end

    if __FILE__ == $0
      GetOpts.new('rest',{'n' => 'nonstop mode'})
      begin
        al=App::List.new
        mdb=Db.new.set('ciax')
        mobj=ExtCmd.new(mdb,al)
        mobj.setcmd(ARGV).exe
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
