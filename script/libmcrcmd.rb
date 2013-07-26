#!/usr/bin/ruby
require "libmcrdb"
require "libmcrrec"
require "libcommand"
require "libinssh"

module CIAX
  module Mcr
    class ExtCmd < Command
      def initialize(mdb,alist,&mcr_proc)
        super()
        @alist=type?(alist,App::List)
        @procs=Procs.new
        @procs[:submcr]=mcr_proc
        @procs[:getstat]=proc{|site| @alist[site].stat}
        @procs[:exec]=proc{|site,cmd|
          ash=@alist[site]
          ash.exe(cmd)
          ash.cobj['sv']['hid']['interrupt']
        }
        ext=self['sv']['ext']=ExtGrp.new(mdb){|id,def_proc|
          ExtItem.new(@procs,mdb,id,def_proc)
        }
        ext.def_proc=proc{|item| item.new_rec.start}
      end
    end

    class ExtItem < ExtItem
      attr_reader :record
      def initialize(procs,mdb,id,def_proc)
        super(mdb,id,def_proc)
        @procs=type?(procs,Hash)
      end

      def new_rec(sh={},valid_keys=[])
        sh['stat']='run'
        @record=Record.new(@cmd,self[:label],valid_keys.clear,@procs)
        @record.extend(Prt) unless $opt['r']
        @procs[:setstat]=proc{|stat| sh['stat']=stat}
        @procs[:query]=proc{|cmds,depth|
          sh['stat']='query'
          if Msg.fg?
            prompt=Msg.color('['+cmds.join('/')+']?',5)
            print Msg.indent(depth.to_i+1)
            res=Readline.readline(prompt,true)
          else
            sleep
            res=Thread.current[:query]
          end
          sh['stat']='run'
          res
        }
        @procs[:show]=proc{|msg| print msg if Msg.fg?}
        self
      end

      def start # separated for sub thread
        puts @record if Msg.fg?
        macro(@select)
        result('done')
        self
      rescue Interlock
        result('error')
        self
      rescue Interrupt
        @appint.call if @appint
        result('interrupted')
        self
      ensure
        @record.fin
      end

      private
      def macro(select,depth=1)
        select.each{|e1|
          begin
            sel=@record.add_step(e1,depth)
            macro(sel,depth+1) if sel
          rescue Retry
            retry
          rescue Skip
            return
          end
        }
        self
      end

      def result(str)
        @procs[:setstat].call(str)
        @record['result']=str
        puts str if Msg.fg?
      end

    end

    if __FILE__ == $0
      GetOpts.new('rest',{'n' => 'nonstop mode'})
      begin
        al=App::List.new
        mdb=Db.new.set('ciax')
        mobj=ExtCmd.new(mdb,al){|cmd,asy|
          mobj.setcmd(cmd).select
        }
        mobj.setcmd(ARGV).exe
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
