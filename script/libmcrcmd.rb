#!/usr/bin/ruby
require "libmcrdb"
require "libmcrrec"
require "libcommand"
require "libinssh"

module CIAX
  module Mcr
    class ExtCmd < Command
      def initialize(mdb,al,&mcr_proc) # Block if for SubMacro
        super()
        sv=self['sv']
        sv['ext']=ExtGrp.new(mdb,[sv.procs])
        sv.procs[:asymcr]=mcr_proc||proc{}
        sv.procs[:submcr]=proc{|cmd| setcmd(cmd) }
        sv.procs[:getstat]=proc{|site| al[site].stat}
        sv.procs[:exec]=proc{|site,cmd| al[site].exe(cmd) }
        sv.procs[:show]=proc{|msg| print msg if Msg.fg?}
        require "libmcrprt" unless $opt['r']
      end
    end

    class ExtGrp < ExtGrp
      def initialize(mdb,procary)
        super(mdb,procary){}
        @mdb=type?(mdb,Mcr::Db)
      end

      def setcmd(cmd)
        id,*par=type?(cmd,Array)
        @valid_keys.include?(id) || raise(InvalidCMD,list)
        ExtItem.new(@mdb,id,@procary).set_par(par)
      end
    end

    class ExtItem < ExtItem
      attr_reader :record
      def new_rec(sh={},valid_keys=[])
        @procs[:setstat]=proc{|stat| sh['stat']=stat}
        @record=Record.new(@cmd,self[:label],valid_keys,@procary)
        @procs[:query]=proc{|prom|
          if Msg.fg?
            Readline.readline(prom,true)
          else
            sleep
            Thread.current[:query]
          end
        }
        self
      end

      def start # separated for sub thread
        @record.start
        macro(@select)
        @record.done
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
        @record.depth+=1
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
        @record.depth-=1
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
