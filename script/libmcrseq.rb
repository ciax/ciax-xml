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
    # Sequencer Layer
    class Seq < Exe
      #required cfg keys: app,db,body,stat,(:submcr_proc)
      attr_reader :cfg,:record,:que_cmd,:que_res,:post_stat_procs,:pre_mcr_procs,:post_mcr_procs,:th_mcr
      #cfg[:submcr_proc] for executing asynchronous submacro, which must returns hash with ['id']
      #ent_cfg should have [:dbi]
      def initialize(ent,attr={})
        type?(ent,Mcr::Entity)
        super(ent.id,ent.cfg,attr)
        type?(@cfg[:sub_list],CIAX::List)
        db=type?(@cfg[:dbi],Dbi)
        @cfg[:output]=@record=Record.new
        @submcr_proc=@cfg[:submcr_proc]||proc{|args,id|
          show(Msg.indent(@step['depth']+1)+"Sub Macro #{args} issued\n")
          {'id' => 'dmy'}
        }
        @post_stat_procs=[] # execute on stat changes
        @pre_mcr_procs=[]
        @post_mcr_procs=[]
        @th_mcr=Thread.current
        @que_cmd=Queue.new
        @que_res=Queue.new
        update({'id'=>@record['id'],'cid'=>@cfg[:cid],'pid'=>@cfg['pid'],'step'=>0,'total_steps'=>@cfg[:batch].size,'stat'=>'ready','option'=>@record.option})
        @running=[]
        # For Thread mode
        @cobj=Index.new(Config.new,@cfg.pick([:jump_groups,:output]))
        @cobj.add_rem.add_hid
        @cobj.rem.add_int(@record.option).valid_clear
        @cobj.rem.int.def_proc{|ent| reply(ent.id)}
        @cobj.rem.int.add_item('start','Sequece Start').def_proc{|ent|
          fork
          'ACCEPT'
        }
      end

      def fork
        @record.start(@cfg)
        @th_mcr=Threadx.new("Macro(#@id)",10){macro}
        @cobj.get('interrupt').def_proc{|ent,src|
          @th_mcr.raise(Interrupt)
          'INTERRUPT'
        }
        self
      end

      def start
        @record.start(@cfg)
        macro
      end

      def to_v
        msg=@record.to_v
        msg << "  [#{self['step']}/#{self['total_steps']}]"
        msg << "(#{self['stat']})"
        msg << optlist(self['option'])
      end

      def ext_shell
        super
        @prompt_proc=proc{
          "(#{self['stat']})"+optlist(self['option'])
        }
        @cobj.loc.add_view #(:output => @cfg[:output])
        self
      end

      private
      def macro
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
                @step['id']=@submcr_proc.call(e1['args'],@record['id'])['id']
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

      # Communicate with forked macro
      def reply(ans)
        if self['stat'] == 'query'
          @que_cmd << ans
          @que_res.pop
        else
          "IGNORE"
        end
      end

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
      GetOpts.new('icemntr')
      proj=ENV['PROJ']||'ciax'
      cfg=Config.new
      cfg[:jump_groups]=[]
      al=Wat::List.new(cfg).cfg[:sub_list] #Take App List
      cfg[:sub_list]=al
      mobj=Index.new(cfg)
      mobj.add_rem
      mobj.rem.add_ext(Db.new.get(proj))
      begin
        ent=mobj.set_cmd(ARGV)
        seq=Seq.new(ent)
        if $opt['i']
          seq.start
        else
          seq.ext_shell.shell
        end
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
