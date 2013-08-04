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
        sv['ext']=ExtGrp.new(mdb,sv.procary)
        sv.procs[:submcr]=mcr_proc
        sv.procs[:getstat]=proc{|site| al[site].stat}
        sv.procs[:exec]=proc{|site,cmd| al[site].exe(cmd) }
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
        sh['stat']='run'
        @record=Record.new(@cmd,self[:label],valid_keys.clear,@procary)
        @record.extend(Prt) unless $opt['r']
        @procs[:setstat]=proc{|stat| sh['stat']=stat}
        @procs[:query]=proc{|cmds,depth|
          if Msg.fg?
            prompt=Msg.color('['+cmds.join('/')+']?',5)
            print Msg.indent(depth.to_i+1)
            res=Readline.readline(prompt,true)
          else
            sleep
            res=Thread.current[:query]
          end
          res
        }
        @procs[:show]=proc{|msg| print msg if Msg.fg?}
        self
      end

      def start # separated for sub thread
        puts @record if Msg.fg?
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
            sel=@record.add_step(e1)
            macro(sel) if sel
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
        mobj=ExtCmd.new(mdb,al){|cmd,asy| mobj.setcmd(cmd).select}
        mobj.setcmd(ARGV).new_rec.start
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
