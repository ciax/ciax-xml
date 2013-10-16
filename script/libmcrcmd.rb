#!/usr/bin/ruby
require "libmcrdb"
require "librecord"
require "libappsh"

module CIAX
  module Mcr
    class Stat < Exe
      attr_reader :running,:cmd_que,:res_que
      attr_accessor :thread
      def initialize(id,mobj)
        super('mcr',id,mobj)
        @running=[]
        @cmd_que=Queue.new
        @res_que=Queue.new
      end
    end

    class Command < Command
      attr_reader :extgrp,:intgrp
      def initialize(upper,al)
        super(upper)
        type?(al,App::List)
        svc={:group_class =>ExtGrp,:entity_class =>ExtEntity,:mobj => self}
        @stq=svc[:save_que]=Queue.new
        svc[:submcr_proc]=proc{|args| setcmd(args) }
        svc[:stat_proc]=proc{|site| al[site].stat}
        svc[:exec_proc]=proc{|site,args| al[site].exe(args) }
        svc[:int_grp]=IntGrp.new(@cfg).def_proc
        @extgrp=@svdom.add_group(svc)
        $dryrun=1
      end

      def ext_proc(&def_proc)
        @extgrp.set_proc(&def_proc)
      end

      def add_int
        @intgrp=@svdom.add_group(:group_class =>IntGrp)
      end

      def save_procs
        Thread.new{
          tc=Thread.current
          tc[:name]="Save Command Thread"
          tc[:color]=9
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
          add_item(id,{:label =>id.capitalize+" "+a[0]})
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
        [:cid,:label].each{|k| @record[k.to_s]=@cfg[k]} # Fixed Value
        @stat=Stat.new(@cfg[:cid],@cfg[:mobj])
      end

      def fork
        @stat.thread=Thread.new{
          tc=Thread.current
          tc[:name]="Macro Thread(#{@cfg[:cid]})"
          tc[:color]=10
          macro
        }
        [@record['id'],@stat]
      end

      # separated for sub thread
      def macro
        @stat[:cid]=@record['cid']
        setstat 'run'
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
        setstat str
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

      def setstat(str)
        @stat[:stat]=str
        @cfg[:save_que].push "#{@stat[:cid]}(#{str})"
      end

      def query(cmds)
        @cfg[:int_grp].valid_keys.replace(cmds)
        @stat[:option]=cmds.join('/')
        setstat 'query'
        Readline.completion_proc=proc{|word| cmds.grep(/^#{word}/)} if Msg.fg?
        res=loop{
          input if Msg.fg?
          cmd=@stat.cmd_que.pop
          break cmd if cmds.include?(cmd)
          @stat.res_que << 'INVALID'
        }
        @stat.res_que << 'OK'
        @stat[:option]=nil
        setstat 'run'
        @step['action']=res
        ent=@cfg[:int_grp].setcmd([res])
        @cfg[:int_grp].valid_keys.clear
        ent.exe
      end

      def input
        @stat.cmd_que << Readline.readline(@step.body("[#{@stat[:option]}]?"),true).rstrip
      end

      # Print section
      def show(msg)
        print msg if Msg.fg?
      end
    end

    if __FILE__ == $0
      GetOpts.new('rest',{'n' => 'nonstop mode'})
      begin
        al=App::List.new
        cfg=Config.new
        cfg[:db]=Db.new.set('ciax')
        mobj=Command.new(cfg,al)
        mobj.setcmd(ARGV).macro
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
