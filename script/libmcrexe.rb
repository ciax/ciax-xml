#!/usr/bin/ruby
require "libmcrcmd"
require "librecord"
require "libappsh"

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
      attr_reader :record,:que_cmd,:que_res,:post_stat_procs
      #exe_proc for executing asynchronous submacro
      def initialize(ment,&exe_proc)
        @cfg=type?(type?(ment,Entity).cfg)
        type?(@cfg[:app_list],App::List)
        @record=Record.new(type?(@cfg[:db],Db)).start(@cfg)
        super('macro',@record['sid'],Command.new(@cfg))
        @exe_proc=exe_proc||proc{{}}
        @post_stat_procs=[] # execute on stat changes
        @que_cmd=Queue.new
        @que_res=Queue.new
        update({'cid'=>@cfg[:cid],'step'=>0,'total_steps'=>@cfg[:body].size,'stat'=>'run','option'=>[]})
        @running=[]
      end

      def optlist
        o=self['option']
        o.empty? ? '' :  color("[#{o.join('/')}]",5)
      end

      def ext_shell
        @cobj.add_int
        @cobj.intgrp.set_proc{|ent| reply(ent.id)}
        self['option']=@cobj.intgrp.valid_keys.clear
        super(@record){
          "(#{self['stat']})"+optlist
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

      def fork
        Threadx.new("Macro Thread(#@id)",12){macro}
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
              @cfg[:app_list][e1['site']].exe(e1['args']) if exec?(@step.exec?)
            when 'mcr'
              if @step.async?
                @step['sid']=@exe_proc.call(e1['args'])['sid']
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
        warn("\nInterrupt Issued to #{@running}")
        @running.each{|site|
          @cfg[:app_list][site].exe(['interrupt'])
        } if $opt['m']
        finish('interrupted')
        self
      ensure
        @post_exe_procs.each{|p| p.call(self)}
      end

      private
      def finish(str='complete')
        @running.clear
        show str+"\n"
        @record.finish(str)
        self['option'].clear
        set_stat str
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
            prom=@step.body(optlist+'?')
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
      GetOpts.new('lnt')
      begin
        cfg=Config.new
        cfg[:app_list]=App::List.new
        cfg[:db]=Db.new.set('ciax')
        cobj=Command.new(cfg)
        cobj.add_ext
        seq=Seq.new(cobj.set_cmd(ARGV))
        if $opt['l']
          seq.fork
          seq.ext_shell.shell
        else
          seq.macro
        end
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
