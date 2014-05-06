#!/usr/bin/ruby
require "libmacrocmd"
require "libmacrorec"
require "libappsh"

module CIAX
  module Mcr
    class Exe < Exe
      #reqired cfg keys: app,db,body,stat
      attr_reader :record,:running,:cmd_que,:res_que,:exe_que,:thread
      def initialize(cobj)
        super('mcr','',cobj)
        type?(cobj.cfg[:app],App::List)
        type?(cobj.cfg[:db],Db)
        @running=[]
        @cmd_que=Queue.new
        @res_que=Queue.new
        @exe_que=Queue.new
        @save_que=Queue.new
        @cobj.ext_proc{|ent|
          @record=Record.new(ent.cfg)
          macro
        }
        @cobj.item_proc('interrupt'){|ent|
          raise(Interrupt)
          'INTERRUPT'
        }
      end

      def ext_shell
        super(@record,{:stat => "(%s)",:option =>"[%s]"})
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

      def fork(ent)
        @record=Record.new(ent.cfg)
        @thread=Threadx.new("Macro Thread(#{ent.id})",10){macro}
        self
      end

      private
      def macro
        set_stat 'run'
        show @record
        cfg=@record.cfg
        cfg[:body].each{|e1|
          begin
            @step=@record.add_step(e1)
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
          cfg[:app][site].exe(['interrupt'])
        } if $opt['m']
        finish('interrupted')
        self
      end

      def finish(str='complete')
        @running.clear
        show str+"\n"
        @record.finish(str)
        self[:option]=nil
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
        self[:stat]=str
      end

      def query(cmds)
        self[:option]=cmds.join('/')
        set_stat 'query'
        res=input(cmds)
        self[:option]=nil
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
            prom=@step.body("[#{self[:option]}]?")
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
        Exe.new(cobj).exe(ARGV)
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
