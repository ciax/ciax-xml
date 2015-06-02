#!/usr/bin/ruby
require "libmcrcmd"
require "librecord"
require "libwatlist"
require "libsh"

module CIAX
  # Modes             | Actual Status? | Force Entering | Query? | Moving | Retry Interval | Record?
  # TEST(default):    | NO  | YES | YES | NO  | 0 | NO
  # NONSTOP TEST(-n): | NO  | YES | NO  | NO  | 0 | NO
  # CHECK(-e):        | YES | YES | YES | NO  | 0 | YES
  # DRYRUN(-ne):      | YES | YES | NO  | NO  | 0 | YES
  # INTERACTIVE(-em): | YES | NO  | YES | YES | 1 | YES
  # NONSTOP(-nem):    | YES | NO  | NO  | YES | 1 | YES

  #MOTION:  TEST <-> REAL (m)
  #QUERY :  INTERACTIVE <-> NONSTOP(n)

  #TEST: query(exec,error,enter), interval=0
  #REAL: query(exec,error), interval=1
  module Mcr
    # Sequencer
    class Seq < Exe
      #required cfg keys: app,db,body,stat
      attr_reader :record,:que_cmd,:que_res,:post_stat_procs,:post_mcr_procs
      #cfg[:submcr_proc] for executing asynchronous submacro
      #ent_cfg should have [:db]
      def initialize(ent_cfg)
        type?(ent_cfg,Config)
        Wat::List.new(ent_cfg) unless ent_cfg.layers.key?(:wat)
        db=type?(ent_cfg[:db],Dbi)
        @record=Record.new(db['id'],db['version']).start(ent_cfg)
        super(@record['sid'])
        @output=@record
        @post_stat_procs=[] # execute on stat changes
        @post_mcr_procs=[]
        @que_cmd=Queue.new
        @que_res=Queue.new
        update({'cid'=>@record.cfg[:cid],'step'=>0,'total_steps'=>@record.cfg[:body].size,'stat'=>'run','option'=>[]})
        @running=[]
        @cobj.item_proc('interrupt'){|ent,src|
          @th_mcr.raise(Interrupt)
          'INTERRUPT'
        }
        ext_shell
      end

      def ext_shell
        intgrp=@cobj.add_intgrp(Int).intgrp
        intgrp.set_proc{|ent| reply(ent.id)}
        self['option']=intgrp.valid_keys.clear
        @prompt_proc=proc{
          res="(#{self['stat']})"
          res+=optlist(self['option']) if key?('option')
          res
        }
        super(@record.cfg[:cid].tr(':','_'))
        vg=@cobj.lodom.add_group('caption'=>"Change View Mode",'color' => 9)
        vg.add_item('vis',"Visual mode").set_proc{@output.vmode='v';''}
        vg.add_item('raw',"Raw mode").set_proc{@output.vmode='r';''}
        self
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
        self
      end

      def macro
        Thread.current[:sid]=@id
        set_stat('run')
        show @record
        @record.cfg[:body].each{|e1|
          self['step']+=1
          begin
            @step=@record.add_step(e1)
            case e1['type']
            when 'mesg'
              @step.ok?
              query(['ok'])
            when 'goal'
              break if @step.skip? && !query(['pass','force'])
            when 'check'
              @step.fail? && query(['drop','force','retry'])
            when 'wait'
              @step.timeout?{show '.'} && query(['drop','force','retry'])
            when 'exec'
              @running << e1['site']
              @record.cfg.layers[:wat].site(e1['site']).exe(e1['args'],'macro') if @step.exec? && query(['exec','skip'])
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
          @record.cfg.layers[:wat].site(site).exe(['interrupt'],'user')
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

      def set_stat(str)
        self['stat']=str
      ensure
        @post_stat_procs.each{|p| p.call(self)}
      end

      def query(cmds)
        return true if $opt['n']
        self['option'].replace(cmds)
        set_stat 'query'
        if $opt['n']
          res=$opt['e'] ? cmds.first : 'ok'
        else
          res=input(cmds)
        end
        self['option'].clear
        set_stat 'run'
        @step['action']=res
        case res
        when 'exec','force','ok'
          return true
        when 'pass'
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
            break 'interrupt' unless line=Readline.readline(prom,true)
            @que_cmd << line.rstrip
          end
          id=@que_cmd.pop.split(/[ :]/).first
          if cmds.include?(id)
            @que_res << 'ACCEPT'
            break id
          elsif !id
            @que_res << ''
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
      GetOpts.new('cemintr')
      begin
        ment=Command.new.add_extgrp.set_cmd(ARGV)
        seq=Seq.new(ment.cfg)
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
