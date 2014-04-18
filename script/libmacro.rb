#!/usr/bin/ruby
require "libmacrocmd"
require "librecord"

module CIAX
  module Mcr
    class Macro
      include Msg
      attr_reader :record,:cmd_que,:res_que,:exe_que
      def initialize(cfg)
        @cfg=Msg.type?(cfg,Config)
        al=type?(@cfg[:app],App::List)
        @record=Record.new
        @record['label']=@cfg['label']
        # Fixed Value
        @cmd_que=Queue.new
        @res_que=Queue.new
        @exe_que=Queue.new
        @running=[]
        @stat={}
        @cfg[:stat_proc]=proc{|site| al[site].stat}
      end

      # separated for sub thread
      def macro
        set_stat 'run'
        show @record
        submacro(@cfg)
        finish
        self
      rescue Interlock
        finish('error')
        self
      rescue Interrupt
        warn("\nInterrupt Issued to #{@stat.running}")
        @stat.running.each{|site|
          @cfg[:app][site].exe(['interrupt'])
        } if $opt['m']
        finish('interrupted')
        self
      end

      private
      def submacro(cfg)
        @record.depth+=1
        cfg[:body].each{|e1|
          begin
            @step=@record.add_step(e1,cfg)
            case e1['type']
            when 'mesg'
              ack?(@step.ok?)
            when 'goal'
              return if skip?(@step.skip?)
            when 'check'
              drop?(@step.fail?)
            when 'wait'
              drop?(@step.timeout?{show '.'})
            when 'exec'
              @running << e1['site']
              cfg[:app][e1['site']].exe(e1['args']) if exec?(@step.exec?)
            when 'mcr'
              if @step.async?
                @exe_que << e1['args']
              else
                submacro(cfg[:mobj].set_cmd(e1['args']).cfg)
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
        @running.clear
        show str+"\n"
        @record.finish(str)
        @cfg[:int_grp].valid_keys.clear
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
        @stat[:stat]=str
      end

      def query(cmds)
        @stat[:option]=cmds.join('/')
        set_stat 'query'
        res=input(cmds)
        @stat[:option]=nil
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
            prom=@step.body("[#{@stat[:option]}]?")
            @cmd_que << Readline.readline(prom,true).rstrip
          end
          id=@cmd_que.pop.split(/[ :]/).first
          if cmds.include?(id)
            @res_que << 'ACCEPT'
            break id
          else
            @res_que << 'INVALID'
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
        cobj=Command.new(cfg)
        ent=cobj.set_cmd(ARGV)
        mobj=Macro.new(ent.cfg).macro
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
