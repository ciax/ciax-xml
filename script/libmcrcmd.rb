#!/usr/bin/ruby
require "libmcrdb"
require "librecord"
require "libcommand"
require "libappsh"

module CIAX
  module Mcr
    class ExtCmd < Command
      def initialize(mdb,al,&def_proc) # Block if for SubMacro
        super()
        svs=initshare(self['sv'].cfg,al,def_proc)
        self['sv']['ext']=ExtGrp.new(mdb,svs){|id,pa|
          ExtItem.new(mdb,id,pa)
        }
        $dryrun=3
      end

      def initshare(svs,al,def_proc)
        svs[:valid_keys]=[]
        @stq=svs[:save_que]=Queue.new
        svs[:def_proc]=def_proc if def_proc
        svs[:submcr_proc]=proc{|args| setcmd(args) }
        svs[:stat_proc]=proc{|site| al[site].stat}
        svs[:exec_proc]=proc{|site,args| al[site].exe(args) }
        svs[:cmdproc]={}
        @intcmd={}
        {
          "exec"=>["Command",proc{true}],
          "skip"=>["Execution",proc{false}],
          "drop"=>[" Macro",proc{true}],
          "suppress"=>["and Memorize",proc{false}],
          "force"=>["Proceed",proc{false}],
          "retry"=>["Checking",proc{raise(Retry)}]
        }.each{|s,a|
          @intcmd[s]=s.capitalize+" "+a[0]
          svs[:cmdproc][s]=a[1]
        }
        svs
      end

      def save_proc
        Thread.new{yield while @stq.pop}
      end

      def int_grp
        ig=self['sv']['int']
        ig.update_items(@intcmd)
        ig.cfg[:def_proc]=proc{|item| yield item}
        ig
      end
    end

    class ExtItem < ExtItem
      def set_par(par)
        super
        @cfg[:select]=@select
        ent=Entity.new(@id,par,@cfg)
        [:cid,:label].each{|k| ent.record[k.to_s]=self[k]} # Fixed Value
        ent
      end
    end

    class Stat < Exe
      attr_reader :running,:cmd_que,:res_que
      attr_accessor :thread
      def initialize(id)
        super('mcr',id)
        @running=[]
        @cmd_que=Queue.new
        @res_que=Queue.new
        delete('id')
        delete('msg')
        delete('layer')
      end
    end

    class Entity < Entity
      attr_reader :record,:stat
      def initialize(id,par,upper)
        super
        @record=Record.new
        @stat=Stat.new(self[:cid])
      end

      def fork
        @stat.thread=Thread.new{macro}
        [@record['id'],@stat]
      end

      # separated for sub thread
      def macro
        @stat[:cid]=@record['cid']
        setstat 'run'
        show @record
        submacro(@cfg[:select])
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
      def submacro(select)
        @record.depth+=1
        select.each{|e1|
          begin
            @step=@record.add_step(e1,@cfg)
            case e1['type']
            when 'goal'
              raise(Skip) if @step.skip?
            when 'check'
              res=@step.fail?
              raise(Interlock) if drop?(res)
            when 'wait'
              res=@step.timeout?{show '.'}
              raise(Interlock) if drop?(res)
            when 'exec'
              @stat.running << e1['site']
              res=@step.exec?
              @cfg[:exec_proc].call(e1['site'],e1['args']) if exec?(res)
            when 'mcr'
              item=@cfg[:submcr_proc].call(e1['args'])
              if @step.async?
                @cfg[:def_proc].call(item)
              else
                submacro(item.cfg[:select])
              end
            end
          rescue Retry
            retry
          rescue Skip
            return
          end
        }
        @record.depth-=1
        self
      end

      def finish(str='complete')
        @stat.running.clear
        show str+"\n"
        @record.finish(str)
        @cfg[:valid_keys].clear
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
        @cfg[:valid_keys].replace(cmds)
        @stat[:option]=cmds.join('/')
        setstat 'query'
        Readline.completion_proc=proc{|word| cmds.grep(/^#{word}/)} if Msg.fg?
        res=loop{
          input if Msg.fg?
          res=@stat.cmd_que.pop
          break res if cmds.include?(res)
          @stat.res_que << 'INVALID'
        }
        @stat.res_que << 'OK'
        @stat[:option]=nil
        setstat 'run'
        @cfg[:valid_keys].clear
        @step['action']=res
        @cfg[:cmdproc][res].call
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
        mdb=Db.new.set('ciax')
        mobj=ExtCmd.new(mdb,al)
        mobj.setcmd(ARGV).macro
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
