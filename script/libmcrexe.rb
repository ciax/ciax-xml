#!/usr/bin/ruby
require "libmcrcmd"
require "librecord"
require "libwatsh"

module CIAX
  # Modes            | Actual Status? | Force Entering | Query? | Moving | Retry Interval
  # TEST(default):   | NO  | YES | YES | NO  | 0
  # CHECK(-e):       | YES | YES | YES | NO  | 0
  # DRYRUN(-ne):     | YES | YES | NO  | NO  | 0
  # INTERACTIVE(-em):| YES | NO  | YES | YES | 1
  # NONSTOP(-nem):   | YES | NO  | NO  | YES | 1

  #MOTION:  TEST <-> REAL (m)
  #QUERY :  INTERACTIVE <-> NONSTOP(n)

  #TEST: query(exec,error,enter), interval=0
  #REAL: query(exec,error), interval=1
  module Mcr
    # Sequencer
    class Seq < Exe
      #reqired cfg keys: app,db,body,stat
      attr_reader :record,:que_cmd,:que_res,:post_stat_procs,:post_mcr_procs
      #cfg[:submcr_proc] for executing asynchronous submacro
      def initialize(ment)
        @cfg=type?(type?(ment,Entity).cfg)
        type?(@cfg[:wat_list],Watch::List)
        @record=Record.new(type?(@cfg[:db],Db)).start(@cfg)
        super('macro',@record['sid'],Command.new)
        @output=@record
        @post_stat_procs=[] # execute on stat changes
        @post_mcr_procs=[]
        @que_cmd=Queue.new
        @que_res=Queue.new
        update({'cid'=>@cfg[:cid],'step'=>0,'total_steps'=>@cfg[:body].size,'stat'=>'run','option'=>[]})
        @running=[]
      end

      def ext_shell
        @cobj.add_int
        @cobj.intgrp.set_proc{|ent| reply(ent.id)}
        self['option']=@cobj.intgrp.valid_keys.clear
        super{
          "(#{self['stat']})"+optlist(self['option'])
        }
      end

      def reply(ans)
        if self['stat'] == 'query'
          @que_cmd << ans
          @que_res.pop
        else
          "IGNORE"
        end
      end

      #Takes ThreadGroup to be added
      def fork(tg=nil)
        th=Threadx.new("Macro(#@id)",10){macro}
        tg.add(th) if tg.is_a?(ThreadGroup)
        ext_shell
        self
      end

      def macro
        Thread.current[:sid]=@id
        set_stat('run')
        show @record
        @cfg[:body].each{|e1|
          self['step']+=1
          begin
            @step=@record.add_step(e1)
            case e1['type']
            when 'mesg'
              ack?(@step.ok?)
            when 'goal'
              break if skip?(@step.skip?)
            when 'check'
              drop?(@step.fail?)
            when 'wait'
              drop?(@step.timeout?{show '.'})
            when 'exec'
              @running << e1['site']
              @cfg[:wat_list][e1['site']].exe(e1['args']) if exec?(@step.exec?)
            when 'mcr'
              if @step.async? && @cfg[:submcr_proc].is_a?(Proc)
                @step['sid']=@cfg[:submcr_proc].call(e1['args'])['sid']
              end
            end
          rescue Retry
            retry
          rescue Skip
          end
        }
        finish
        self
      rescue Interlock
        finish('error')
        self
      rescue Interrupt
        msg("\nInterrupt Issued to running devices #{@running}")
        @running.each{|site|
          @cfg[:wat_list][site].exe(['interrupt'])
        } if $opt['m']
        finish('interrupted')
        self
      end

      private
      def finish(str='complete')
        @running.clear
        show str+"\n"
        @record.finish(str)
        self['option'].clear
        set_stat str
        @post_mcr_procs.each{|p| p.call(self)}
        self
      end

      # Interactive section
      def ack?(res)
        $opt['n'] || query(['ok'])
      end

      def skip?(res)
        return res if $opt['n']
        res && !query(['pass','force'])
      end

      def drop?(res)
        if res
          raise(Interlock) if $opt['n']
          query(['drop','force','retry'])
        end
      end

      def exec?(res)
        return res if $opt['n']
        res && query(['exec','skip'])
      end

      def set_stat(str)
        self['stat']=str
      ensure
        @post_stat_procs.each{|p| p.call(self)}
      end

      def query(cmds)
        self['option'].replace(cmds)
        set_stat 'query'
        res=input(cmds)
        self['option'].clear
        set_stat 'run'
        @step['action']=res
        case res
        when 'exec','force'
          return true
        when 'pass','ok'
          return false
        when 'skip'
          raise(Skip)
        when 'drop'
          raise(Interlock)
        when 'retry'
          raise(Retry)
        end
      end

      def input(cmds)
        Readline.completion_proc=proc{|word| cmds.grep(/^#{word}/)} if Msg.fg?
        loop{
          if Msg.fg?
            prom=@step.body(optlist(self['option']))
            @que_cmd << Readline.readline(prom,true).rstrip
          end
          id=@que_cmd.pop.split(/[ :]/).first
          if cmds.include?(id)
            @que_res << 'ACCEPT'
            break id
          else
            @que_res << 'INVALID'
          end
        }
      end

      # Print section
      def show(msg)
        print msg if Msg.fg?
      end
    end


    if __FILE__ == $0
      GetOpts.new('emlnt')
      begin
        cfg=Config.new('mcr_exe')
        cfg[:wat_list]=Watch::List.new
        cfg[:db]=Db.new.set('ciax')
        cobj=Command.new(cfg)
        cobj.add_ext
        seq=Seq.new(cobj.set_cmd(ARGV))
        if $opt['l']
          seq.fork.shell
        else
          seq.macro
        end
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
