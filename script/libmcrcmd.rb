#!/usr/bin/ruby
require "libmcrdb"
require "libmcrrec"
require "libcommand"
require "libinssh"

module CIAX
  module Mcr
    class ExtCmd < Command
      def initialize(mdb,al,&def_proc) # Block if for SubMacro
        super()
        svs=self['sv'].share
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
          "Done Macro"=>proc{true},
          "Force Proceed"=>proc{false},
          "Retry Checking"=>proc{raise(Retry)}
        }.each{|str,v|
          k=str[0].downcase
          (svs[:cmds]||={})[k]=str.split(' ').first
          (svs[:cmdlist]||={})[k]=str
          (svs[:cmdproc]||={})[k]=v
        }
        self['sv']['ext']=ExtGrp.new(mdb,[svs])
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
        @share[:msh]=msh
        @share[:valid_keys]=valid_keys.clear
        @share[:depth]=0
        @share[:running]=[]
        @record=Record.new(self)
        self
      end

      def start # separated for sub thread
        @record.start
        macro(@select)
        @record.finish
        self
      rescue Interlock
        @record.error
        self
      rescue Interrupt
        @record.interrupt
        self
      end

      private
      def macro(select)
        @record.push
        select.each{|e1|
          begin
            if item=@record.add_step(e1)
              macro(item.select)
            end
          rescue Retry
            retry
          rescue Skip
            return
          end
        }
        @record.pop
        self
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
