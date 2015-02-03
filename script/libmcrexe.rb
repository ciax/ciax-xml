#!/usr/bin/ruby
require "libmcrcmd"
require "librecord"
require "libwatexe"

module CIAX
  # Modes            | Actual Status? | Force Entering | Query? | Moving | Retry Interval | Record?
  # TEST(default):   | NO  | YES | YES | NO  | 0 | NO
  # CHECK(-e):       | YES | YES | YES | NO  | 0 | YES
  # DRYRUN(-ne):     | YES | YES | NO  | NO  | 0 | YES
  # INTERACTIVE(-em):| YES | NO  | YES | YES | 1 | YES
  # NONSTOP(-nem):   | YES | NO  | NO  | YES | 1 | YES

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
        cfg=type?(type?(ment,Entity).cfg)
        type?(cfg[:wat_list],Wat::List)
        @record=Record.new(type?(cfg[:db],Db)).start(cfg)
        super(@record['sid'],cfg)
        @output=@record
        @post_stat_procs=[] # execute on stat changes
        @post_mcr_procs=[]
        @que_cmd=Queue.new
        @que_res=Queue.new
        update({'cid'=>@cfg[:cid],'step'=>0,'total_steps'=>@cfg[:body].size,'stat'=>'run','option'=>[]})
        @running=[]
        @cobj.item_proc('interrupt'){|ent,src|
          @th_mcr.raise(Interrupt)
          'INTERRUPT'
        }
      end

      def ext_shell
        @cobj.add_int
        @cobj.intgrp.set_proc{|ent| reply(ent.id)}
        self['option']=@cobj.intgrp.valid_keys.clear
        @prompt_proc=proc{
          res="(#{self['stat']})"
          res+=optlist(self['option']) if key?('option')
          res
        }
        super(@cfg[:cid].tr(':','_'))
        vg=@cobj.lodom.add_group('caption'=>"Change View Mode",'color' => 9)
        vg.add_item('vis',"Visual mode").set_proc{@output.vmode='v';''}
        vg.add_item('raw',"Raw mode").set_proc{@output.vmode='r';''}
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
        @th_mcr=Threadx.new("Macro(#@id)",10){macro}
        tg.add(@th_mcr) if tg.is_a?(ThreadGroup)
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
              @cfg[:wat_list].get(e1['site']).exe(e1['args']) if exec?(@step.exec?)
            when 'mcr'
              if @step.async? && @cfg[:submcr_proc].is_a?(Proc)
                @step['sid']=@cfg[:submcr_proc].call(e1['args'],@id)['sid']
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
        interrupt
      end

      private
      def interrupt
        msg("\nInterrupt Issued to running devices #{@running}",3)
        @running.each{|site|
          @cfg[:wat_list].get(site).exe(['interrupt'],'user')
        } if $opt['m']
        finish('interrupted')
        self
      end

      def finish(str='complete')
        @running.clear
        show str+"\n"
        @record.finish(str)
        self['option'].clear
        @step.delete('option')
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
        when 'interrupt'
          raise(Interrupt)
        end
      end

      def input(cmds)
        Readline.completion_proc=proc{|word| cmds.grep(/^#{word}/)} if Msg.fg?
        loop{
          if Msg.fg?
            prom=@step.body(optlist(self['option']))
            line=Readline.readline(prom,true)||'interrupt'
            @que_cmd << line.rstrip
          end
          id=@que_cmd.pop.split(/[ :]/).first
          if (cmds+['interrupt']).include?(id)
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

    class ConfExe < ConfCmd
      def initialize(name='mcr',proj=nil)
        super
        self[:wat_list]=Wat::List.new
      end
    end

    if __FILE__ == $0
      GetOpts.new('emintr')
      begin
        cobj=Command.new(ConfExe.new).add_ext
        seq=Seq.new(cobj.set_cmd(ARGV))
        if $opt['i']
          seq.macro
        else
          seq.fork.shell
        end
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
