#!/usr/bin/ruby
require "libmcrdb"
require "librecord"
require "libcommand"
require "libappsh"

module CIAX
  module Mcr
    class ExtCmd < Command
      def initialize(mdb,al,stq=Queue.new,&def_proc) # Block if for SubMacro
        super()
        svs=initshare(self['sv'].set,al,def_proc)
        svs[:stat_trig]=stq
        self['sv']['ext']=ExtGrp.new(mdb,[svs])
        $dryrun=3
      end

      def initshare(svs,al,def_proc)
        svs[:def_proc]=def_proc if def_proc
        svs[:submcr_proc]=proc{|args| setcmd(args) }
        svs[:stat_proc]=proc{|site| al[site].stat}
        svs[:exec_proc]=proc{|site,args| al[site].exe(args) }
        cv={:cmdlist => {},:cmdproc => {}}
        {
          "exec"=>["Command",proc{true}],
          "skip"=>["Execution",proc{false}],
          "drop"=>[" Macro",proc{true}],
          "suppress"=>["and Memorize",proc{false}],
          "force"=>["Proceed",proc{false}],
          "retry"=>["Checking",proc{raise(Retry)}]
        }.each{|s,a|
          cv[:cmdlist][s]=s.capitalize+" "+a[0]
          cv[:cmdproc][s]=a[1]
        }
        svs.update(cv)
      end
    end

    class ExtGrp < ExtGrp
      def initialize(mdb,upper)
        super(mdb,upper){}
        @mdb=type?(mdb,Mcr::Db)
      end

      def setcmd(args)
        id,*par=type?(args,Array)
        @valid_keys.include?(id) || raise(InvalidCMD,list)
        ExtItem.new(@mdb,id,@get).set_par(par)
      end
    end

    class ExtItem < ExtItem
      attr_reader :record
      def fork(valid_keys=[])
        new_rec(valid_keys)
        Thread.new{macro}
      end

      def start(valid_keys=[])
        new_rec(valid_keys)
        macro
      end

      private
      def new_rec(valid_keys=[])
        @set[:valid_keys]=valid_keys.clear
        @running=[]
        @record=Record.new
        [:cid,:label].each{|k| @record[k.to_s]=self[k]} # Fixed Value
        self
      end

      # separated for sub thread
      def macro
        @tc=Thread.current
        @tc[:id]=@record['id']
        @tc[:eid]=@tc[:cid]=@record['cid']
        @tc[:queue]=Queue.new
        setstat 'run'
        show @record
        submacro(@select)
        finish
        self
      rescue Interlock
        finish('error')
        self
      rescue Interrupt
        warn("\nInterrupt Issued to #{@running}")
        @running.each{|site|
          @get[:exec_proc].call(site,['interrupt'])
        }
        finish('interrupted')
        self
      end

      def submacro(select)
        @record.depth+=1
        select.each{|e1|
          begin
            @step=@record.add_step(e1,@get)
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
              @running << e1['site']
              res=@step.exec?
              @get[:exec_proc].call(e1['site'],e1['args']) if exec?(res)
            when 'mcr'
              item=@get[:submcr_proc].call(e1['args'])
              if @step.async?
                @get[:def_proc].call(item)
              else
                submacro(item.select)
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
        @running.clear
        show str+"\n"
        @record.finish(str)
        @get[:valid_keys].clear
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
        @tc[:stat]=str
        @get[:stat_trig].push "#{@tc[:cid]}(#{str})"
      end

      def query(cmds)
        vk=@get[:valid_keys].replace(cmds)
        msg=vk.join('/')
        @tc[:option]=msg
        setstat 'query'
        input if Msg.fg?
        res=@tc[:queue].pop
        @tc[:option]=nil
        setstat 'run'
        vk.clear
        @step['action']=res
        @get[:cmdproc][res].call
      end

      def input
        vk=@tc[:option].split('/')
        begin
          Readline.completion_proc=proc{|word| vk.grep(/^#{word}/)}
          res=Readline.readline(@step.body("[#{@tc[:option]}]?"),true).rstrip
        end until vk.include?(res)
        @tc[:queue] << res
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
        mobj.setcmd(ARGV).start
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
