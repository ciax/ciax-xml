#!/usr/bin/ruby
require "libmcrcmd"
require "librecord"
require "libwatexe"

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
    class Seq < Hashx
      #required cfg keys: app,db,body,stat,(:submcr_proc)
      attr_reader :record,:que_cmd,:que_res,:post_stat_procs,:post_mcr_procs
      #cfg[:submcr_proc] for executing asynchronous submacro
      #ent_cfg should have [:dbi]
      def initialize(cfg,attr={})
        @cfg=cfg.gen(self).update(attr)
        type?(@cfg[:sub_list],CIAX::List)
        db=type?(@cfg[:dbi],Dbi)
        @submcr_proc=@cfg[:submcr_proc]||proc{|args,id|
          show(Msg.indent(@step['depth']+1)+"Sub Macro #{args} issued\n")
          {'sid' => 'dmy'}
        }
        @record=Record.new(db['id'],@cfg['ver']).start(@cfg)
        @post_stat_procs=[] # execute on stat changes
        @post_mcr_procs=[]
        @que_cmd=Queue.new
        @que_res=Queue.new
        update({'cid'=>@cfg[:cid],'step'=>0,'total_steps'=>@cfg[:batch].size,'stat'=>'run','option'=>[]})
        @running=[]
      end

      def macro
        Thread.current[:sid]=@record['sid']
        set_stat('run')
        show @record
        @cfg[:batch].each{|e1|
          self['step']+=1
          begin
            @step=@record.add_step(e1)
            case e1['type']
            when 'mesg'
              @step.ok?
              query(['ok'])
            when 'goal'
              break if @step.skip? && !query(['skip','force'])
            when 'check'
              @step.fail? && query(['drop','force','retry'])
            when 'wait'
              @step.timeout?{show '.'} && query(['drop','force','retry'])
            when 'exec'
              @running << e1['site']
              @cfg[:sub_list].get(e1['site']).exe(e1['args'],'macro') if @step.exec? && query(['exec','skip'])
            when 'mcr'
              if @step.async? && @submcr_proc.is_a?(Proc)
                @step['sid']=@submcr_proc.call(e1['args'],@record['sid'])['sid']
              end
            end
          rescue Retry
            retry
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
          @cfg[:sub_list].get(site).exe(['interrupt'],'user')
        } if $opt['m']
        finish('interrupted')
        self
      end

      def finish(str='complete')
        @running.clear
        show str+"\n"
        @record.finish(str)
        self['option'].clear
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
        when 'skip'
          return false
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
            id=line.rstrip
          else
            id=@que_cmd.pop.split(/[ :]/).first
          end
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
      require "libmcrdb"
      GetOpts.new('cemntr')
      proj=ENV['PROJ']||'ciax'
      cfg=Config.new
      cfg[:jump_groups]=[]
      al=Wat::List.new(cfg).cfg[:sub_list] #Take App List
      cfg[:sub_list]=al
      cobj=Index.new(cfg)
      cobj.rem.add_ext(Db.new.get(proj))
      begin
        ent=cobj.set_cmd(ARGV)
        seq=Seq.new(ent.cfg)
        seq.macro
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
