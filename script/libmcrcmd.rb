#!/usr/bin/ruby
require "libmcrdb"
require "libmcrrec"
require "libcommand"
require "libinssh"

module CIAX
  module Mcr
    class ExtCmd < Command
      def initialize(mdb,alist,sh={:valid_keys =>[]},&mcr_proc)
        super()
        @sh=type?(sh,Hash)
        @alist=type?(alist,App::List)
        @procs=Procs.new
        @procs[:submcr]=mcr_proc
        @procs[:setstat]=proc{|stat| @sh['stat']=stat}
        @procs[:getstat]=proc{|site| @alist[site].stat}
        @procs[:exec]=proc{|site,cmd|
          ash=@alist[site]
          ash.exe(cmd)
          ash.cobj['sv']['hid']['interrupt']
        }
        @procs[:query]=proc{|cmds,depth|
          tc=Thread.current
          vk=@sh[:valid_keys].clear
          cmds.each{|s| vk << s[0].downcase}
          @sh['stat']='query'
          if Msg.fg?
            prompt=Msg.color('['+cmds.join('/')+']?',5)
            print Msg.indent(depth.to_i+1)
            res=Readline.readline(prompt,true)
          else
            sleep
            res=tc[:query]
          end
          @sh['stat']='run'
          vk.clear
          res
        }
        ext=self['sv']['ext']=ExtGrp.new(mdb){|id,def_proc|
          ExtItem.new(@procs,mdb,id,def_proc)
        }
        ext.def_proc=proc{|item| item.start}
      end
    end

    class ExtItem < ExtItem
      def initialize(procs,mdb,id,def_proc)
        super(mdb,id,def_proc)
        @procs=type?(procs,Hash)
      end

      def start # separated for sub thread
        @record=Record.new(@cmd,self[:label],@procs)
        @record.extend(Prt) unless $opt['r']
        @procs[:setstat].call('run')
        puts @record if Msg.fg?
        macro(self)
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
            step=@record.add_step(e1,depth)
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
              @appint=step.exec
              puts step.action if Msg.fg?
            when 'mcr'
              puts step if Msg.fg?
              item=setcmd(e1['cmd'])
              if /true|1/ === e1['async']
                @procs[:submcr].call(item)
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
        @procs[:setstat].call(str)
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
