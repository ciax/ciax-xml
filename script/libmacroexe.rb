#!/usr/bin/ruby
require "libmacrocmd"
require "libmacrorec"
require "libappsh"

module CIAX
  module Mcr
    class Ques
      attr_reader :cmd,:res,:exe,:save
      def initialize
        @cmd=Queue.new
        @res=Queue.new
        @exe=Queue.new
        @save=Queue.new
      end
    end

    class Macro < Hashx
      include Msg
      #reqired cfg keys: app,db,body,stat
      attr_reader :running,:ques,:thread
      def initialize(ent)
        @cfg=type?(type?(ent,Entity).cfg)
        type?(@cfg[:app],App::List)
        @ques=Ques.new
        @record=Record.new(type?(@cfg[:db],Db)).start(@cfg)
        self[:cid]=@cfg[:cid]
        self[:sid]=@record['sid']
        @running=[]
      end

      def fork
        @thread=Threadx.new("Macro Thread(#{@id})",10){exe}
        self
      end

      def exe
        set_stat 'run'
        show @record
        @cfg[:body].each{|e1|
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
              @cfg[:app][e1['site']].exe(e1['args']) if exec?(@step.exec?)
            when 'mcr'
              if @step.async?
                @ques.exe << e1['args']
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
          @cfg[:app][site].exe(['interrupt'])
        } if $opt['m']
        finish('interrupted')
        self
      end

      private
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
            @ques.cmd << Readline.readline(prom,true).rstrip
          end
          id=@ques.cmd.pop.split(/[ :]/).first
          if cmds.include?(id)
            @ques.res << 'ACCEPT'
            break id
          else
            @ques.res << 'INVALID'
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
        ent=Command.new(cfg).set_cmd(ARGV)
        Macro.new(ent).exe
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
