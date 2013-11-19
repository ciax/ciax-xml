#!/usr/bin/ruby
require "libmcrdb"
require "librecord"
require "libappsh"
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


module CIAX
  module Mcr
    class Stat < Exe
      attr_reader :running,:cmd_que,:res_que
      attr_accessor :thread
      def initialize(ent)
        @entity=type?(ent,ExtEntity)
        super('mcr',ent.id,ent.cfg[:mobj])
        @running=[]
        @cmd_que=Queue.new
        @res_que=Queue.new
        @cobj.item_proc('interrupt'){|ent|
          @thread.raise(Interrupt)
          'INTERRUPT'
        }
      end

      def ext_shell
        super(@entity.record,{:stat => "(%s)",:option =>"[%s]"})
        @cobj.add_int.set_proc{|ent|
          if self[:stat] == 'query'
            @cmd_que.push ent.id
            @res_que.pop
          else
            'IGNORE'
          end
        }
        self
      end
    end

    class Command < Command
      attr_reader :extgrp,:intgrp
      def initialize(upper)
        super
        al=type?(@cfg[:app],App::List)
        svc={:group_class =>ExtGrp,:entity_class =>ExtEntity,:mobj => self}
        @stq=svc[:save_que]=Queue.new
        svc[:submcr_proc]=proc{|args| set_cmd(args) }
        svc[:stat_proc]=proc{|site| al[site].stat}
        svc[:exec_proc]=proc{|site,args| al[site].exe(args) if $opt['m'] }
        svc[:int_grp]=IntGrp.new(@cfg).def_proc
        @extgrp=@svdom.add_group(svc)
      end

      def ext_proc(&def_proc)
        @extgrp.set_proc(&def_proc)
      end

      def add_int(crnt={})
        crnt[:group_class]=IntGrp
        @intgrp=@svdom.add_group(crnt)
      end

      def save_procs
        Threadx.new("Mcr Save Command Thread",9){
          yield while @stq.pop
        }
      end
    end

    class IntGrp < Group
      def initialize(upper,crnt={})
        super
        @cfg['caption']='Internal Commands'
        @procs={}
        {
          "exec"=>["Command",proc{'EXEC'}],
          "skip"=>["Execution",proc{raise(Skip)}],
          "drop"=>[" Macro",proc{raise(Interlock)}],
          "suppress"=>["and Memorize",proc{'SUP'}],
          "force"=>["Proceed",proc{'FORCE'}],
          "retry"=>["Checking",proc{raise(Retry)}]
        }.each{|id,a|
          add_item(id,id.capitalize+" "+a[0])
          @procs[id]=a[1]
        }
      end

      def def_proc
        @procs.each{|id,prc|
          self[id].set_proc(&prc)
        }
        self
      end
    end

    class ExtEntity < ExtEntity
      attr_reader :record,:stat
      def initialize(upper,crnt)
        super
        @record=Record.new
        # Fixed Value
        @record['cid']=@id
        @record['label']=@cfg['label']
        @stat=Stat.new(self)
        @stat[:cid]=@id
     end

      def fork
        @stat.thread=Threadx.new("Macro Thread(#{@id})",10){macro}
        [@record['id'],@stat]
      end

      # separated for sub thread
      def macro
        set_stat 'run'
        show @record
        submacro(@cfg[:body])
        finish
        self
      rescue Interlock
        finish('error')
        self
      rescue Interrupt
        warn("\nInterrupt Issued to #{@stat.running}")
        @stat.running.each{|site|
          @cfg[:exec_proc].call(site,['interrupt'])
        }
        finish('interrupted')
        self
      end

      private
      def submacro(body)
        @record.depth+=1
        body.each{|e1|
          begin
            @step=@record.add_step(e1,@cfg)
            case e1['type']
            when 'goal'
              return if @step.skip?
            when 'check'
              drop?(@step.fail?)
            when 'wait'
              drop?(@step.timeout?{show '.'})
            when 'exec'
              @stat.running << e1['site']
              @cfg[:exec_proc].call(e1['site'],e1['args']) if exec?(@step.exec?)
            when 'mcr'
              item=@cfg[:submcr_proc].call(e1['args'])
              if @step.async?
                @cfg[:def_proc].call(item)
              else
                submacro(item.cfg[:body])
              end
            end
          rescue Retry
            retry
          rescue Skip
          end
        }
        @record.depth-=1
        self
      end

      def finish(str='complete')
        @stat.running.clear
        show str+"\n"
        @record.finish(str)
        @cfg[:int_grp].valid_keys.clear
        set_stat str
      end

      # Interactive section
      def drop?(res)
        return res if $opt['n']
        res && query(['drop','force','retry'])
      end

      def exec?(res)
        return res if $opt['n']
        res && query(['exec','skip'])
      end

      def set_stat(str)
        @stat[:stat]=str
        @cfg[:save_que].push "#{@stat[:cid]}(#{str})"
      end

      def query(cmds)
        @cfg[:int_grp].valid_keys.replace(cmds)
        @stat[:option]=cmds.join('/')
        set_stat 'query'
        res=input(cmds)
        @stat[:option]=nil
        set_stat 'run'
        @step['action']=res
        ent=@cfg[:int_grp].set_cmd([res])
        @cfg[:int_grp].valid_keys.clear
        ent.exe
      end

      def input(cmds)
        Readline.completion_proc=proc{|word| cmds.grep(/^#{word}/)} if Msg.fg?
        loop{
          if Msg.fg?
            prom=@step.body("[#{@stat[:option]}]?")
            @stat.cmd_que << Readline.readline(prom,true).rstrip
          end
          id=@stat.cmd_que.pop.split(/[ :]/).first
          if cmds.include?(id)
            @stat.res_que << 'ACCEPT'
            break id
          else
            @stat.res_que << 'INVALID'
          end
        }
      end

      # Print section
      def show(msg)
        print msg if Msg.fg?
      end
    end

    if __FILE__ == $0
      GetOpts.new('renmst')
      begin
        cfg=Config.new
        cfg[:app]=App::List.new
        cfg[:db]=Db.new.set('ciax')
        mobj=Command.new(cfg)
        mobj.set_cmd(ARGV).macro
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
