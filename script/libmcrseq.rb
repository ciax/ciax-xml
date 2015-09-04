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
        @mcfg=type?(ent,Mcr::Entity).cfg
        super(ent.id,Config.new,attr)
        type?(@mcfg[:sub_list],CIAX::List)
        type?(@mcfg[:dbi],Dbi)
        @record=Record.new.ext_file(true) # Make latest link
        @submcr_proc=@mcfg[:submcr_proc]||proc{|args,id|
          show{"Sub Macro #{args} issued\n"}
          {'id' => 'dmy'}
        }
        @post_stat_procs=[] # execute on stat changes
        @pre_mcr_procs=[]
        @post_mcr_procs=[]
        @th_mcr=Thread.current
        @que_cmd=Queue.new
        @que_res=Queue.new
        update({'id'=>@record['id'],'cid'=>@mcfg[:cid],'pid'=>@mcfg['pid'],'step'=>0,'total_steps'=>@mcfg[:batch].size,'stat'=>'ready','option'=>[]})
        @running=[]
        @depth=0
        # For Thread mode
        @cobj=Index.new(@cfg)
        @cobj.add_rem.add_hid
        @cobj.rem.add_int(self['option']).valid_clear
        @cobj.rem.int.def_proc{|ent| reply(ent.id)}
        @cobj.rem.int.add_item('start','Sequece Start').def_proc{|ent|
          fork
          'ACCEPT'
        }
      end

      def fork
        @th_mcr=Threadx.new("Macro(#@id)",10){macro}
        @cobj.get('interrupt').def_proc{|ent,src|
          @th_mcr.raise(Interrupt)
          'INTERRUPT'
        }
        self
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
        @cfg[:output]=@record
        @cobj.loc.add_view
        self
      end

      def macro
        @record.start(@mcfg)
        show{@record}
        sub_macro(@mcfg[:batch],@record)
      rescue Interrupt
        msg("\nInterrupt Issued to running devices #{@running}",3)
        @running.each{|site|
          @mcfg[:sub_list].get(site).exe(['interrupt'],'user')
        }
      ensure
        @running.clear
        self['option'].clear
        res=@record.finish
        show{"#{res}"}
        set_stat(res)
        @post_mcr_procs.each{|p| p.call(self)}
      end

      private
      # macro returns result
      def sub_macro(batch,mstat)
        @depth+=1
        set_stat('run')
        result='complete'
        batch.each{|e1|
          self['step']+=1
          begin
            @step=@record.add_step(e1,@depth)
            case e1['type']
            when 'mesg'
              @step.ok?
              query(['ok'])
            when 'goal'
              if @step.skip? && query(['skip','force'])
                result='skipped'
                break
              end
            when 'check'
              if @step.fail? && query(['drop','force','retry'])
                result='error'
                return
              end
            when 'wait'
              if @step.timeout?{show('.')} && query(['drop','force','retry'])
                result='timeout'
                return
              end
            when 'exec'
              if @step.exec? && query(['exec','pass'])
                @running << e1['site']
                @mcfg[:sub_list].get(e1['site']).exe(e1['args'],'macro') 
              end
            when 'mcr'
              if @step.async?
                if @submcr_proc.is_a?(Proc)
                  @step['id']=@submcr_proc.call(e1['args'],@record['id'])['id']
                end
              else
                res=sub_macro(@mcfg.ancestor(2).set_cmd(e1['args']).cfg[:batch],@step)
                result=@step['result']
                return unless res
              end
            end
          rescue Retry
            retry
          end
        }
        true
      rescue Interrupt
        result='interrupted'
        raise Interrupt
      ensure
        mstat['result']=result
        @depth-=1
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

      def set_stat(str)
        self['stat']=str
      ensure
        @post_stat_procs.each{|p| p.call(self)}
      end

      def query(cmds)
        return true if $opt['n']
        self['option'].replace(cmds)
        set_stat 'query'
        res=input(cmds)
        self['option'].clear
        set_stat 'run'
        @step['action']=res
        case res
        when 'retry'
          raise(Retry)
        when 'interrupt'
          raise(Interrupt)
        when 'force','pass'
          false
        else
          true
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
      def show(str=nil)
        return unless Msg.fg?
        if defined? yield
          puts indent(@depth)+yield.to_s
        else
          print str
        end
      end
    end

    if __FILE__ == $0
      GetOpts.new('icemntr')
      cfg=Config.new
      cfg[:jump_groups]=[]
      al=Wat::List.new(cfg).cfg[:sub_list] #Take App List
      cfg[:sub_list]=al
      mobj=Index.new(cfg)
      mobj.add_rem
      mobj.rem.add_ext(Db.new.get(PROJ))
      begin
        ent=mobj.set_cmd(ARGV)
        seq=Seq.new(ent)
        if $opt['i']
          seq.macro
        else
          seq.ext_shell.shell
        end
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
