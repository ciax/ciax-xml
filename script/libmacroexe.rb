#!/usr/bin/ruby
require "libmacrocmd"
require "libmacrorec"
require "libappsh"

module CIAX
  module Mcr
    class Macro < Hashx
      include Msg
      #reqired cfg keys: app,db,body,stat
      attr_reader :record,:sid,:que_cmd,:que_res,:total,:post_procs
      #exe_proc for executing asynchronous submacro
      def initialize(ent,&exe_proc)
        @cfg=type?(type?(ent,Entity).cfg)
        type?(@cfg[:app],App::List)
        @exe_proc=exe_proc||proc{{}}
        @post_procs=[] # execute at the end of exe
        @que_cmd=Queue.new
        @que_res=Queue.new
        @record=Record.new(type?(@cfg[:db],Db)).start(@cfg)
        @sid=@record['sid']
        self[:cid]=@cfg[:cid]
        @total=@cfg[:body].size
        self[:step]=0
        @running=[]
      end

      def exe
        Thread.current[:sid]=@sid
        set_stat 'run'
        show @record
        @cfg[:body].each{|e1|
          self[:step]+=1
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
                @step['sid']=@exe_proc.call(e1['args'])['sid']
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
      ensure
        @post_procs.each{|p| p.call(self)}
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
            @que_cmd << Readline.readline(prom,true).rstrip
          end
          id=@que_cmd.pop.split(/[ :]/).first
          if cmds.include?(id)
            @que_res << 'ACCEPT'
            break id
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
