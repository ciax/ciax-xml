#!/usr/bin/ruby
require "libmcrdb"
require "librecord"
require "libcommand"
require "libinssh"

module CIAX
  module Mcr
    class ExtCmd < Command
      def initialize(mdb,al,&def_proc) # Block if for SubMacro
        super()
        svs=initshare(self['sv'].share,al,def_proc)
        self['sv']['ext']=ExtGrp.new(mdb,[svs])
      end

      def initshare(svs,al,def_proc)
        svs[:def_proc]=def_proc if def_proc
        svs[:submcr_proc]=proc{|args| setcmd(args) }
        svs[:stat_proc]=proc{|site| al[site].stat}
        svs[:exec_proc]=proc{|site,args| al[site].exe(args) }
        svs[:show_proc]=proc{|msg| print msg if Msg.fg?}
        svs[:query_proc]=proc{|msg|
          if Msg.fg?
            Readline.readline(msg,true)
          else
            sleep
            Thread.current[:query]
          end
        }
        {
          "Exec Command"=>proc{true},
          "Skip Execution"=>proc{false},
          "Drop Macro"=>proc{true},
          "Force Proceed"=>proc{false},
          "Retry Checking"=>proc{raise(Retry)}
        }.each{|str,v|
          k=str[0].downcase
          (svs[:cmds]||={})[k]=str.split(' ').first
          (svs[:cmdlist]||={})[k]=str
          (svs[:cmdproc]||={})[k]=v
        }
        svs
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
        ExtItem.new(@mdb,id,@shary).set_par(par)
      end
    end

    class ExtItem < ExtItem
      attr_reader :record
      def new_rec(msh={},valid_keys=[])
        @share[:valid_keys]=valid_keys.clear
        @running=[]
        @record=Record.new
        [:cid,:label].each{|k| @record[k.to_s]=self[k]} # Fixed Value
        @share[:setstat]=proc{|str,opt| # Variable Value
          @record['stat']=msh['stat']=str
          @record['option']=msh['option']=opt
          @record.save
        }
        self
      end

      def start # separated for sub thread
        @shary[:setstat].call('run')
        @shary[:show_proc].call(@record)
        macro(@select)
        finish
        self
      rescue Interlock
        finish('error')
        self
      rescue Interrupt
        warn("\nInterrupt Issued to #{@shary[:running]}]")
        @running.each{|site|
          @shary[:exec_proc].call(site,['interrupt'])
        }
        finish('interrupted')
        self
      end

      private
      def macro(select)
        @record.depth+=1
        select.each{|e1|
          begin
            step=@record.add_step(e1,@shary)
            print step.title if Msg.fg?
            case e1['type']
            when 'goal'
              res=step.skip?
              print step.result if Msg.fg?
              raise(Skip) if res
            when 'check'
              res=step.fail?
              print step.result if Msg.fg?
              raise(Interlock) if step.drop?(res)
            when 'wait'
              res=step.timeout?{
                print '.' if Msg.fg?
                @shary[:setstat].call('wait')
              }
              @shary[:setstat].call('run')
              print step.result if Msg.fg?
              raise(Interlock) if step.drop?(res)
            when 'exec'
              @running << e1['site']
              @shary[:exec_proc].call(e1['site'],e1['cmd']) if step.exec?
              print step.result if Msg.fg?
            when 'mcr'
              print step.result if Msg.fg?
              item=@shary[:submcr_proc].call(e1['cmd'])
              if step.async?
                @shary[:def_proc].call(item)
              else
                macro(item.select)
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
        @shary[:show_proc].call(str+"\n")
        @record.finish(str)
        @shary[:valid_keys].clear
        @shary[:setstat].call('done')
      end
    end

    if __FILE__ == $0
      GetOpts.new('rest',{'n' => 'nonstop mode'})
      begin
        al=App::List.new
        mdb=Db.new.set('ciax')
        mobj=ExtCmd.new(mdb,al)
        mobj.setcmd(ARGV).new_rec.start
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
