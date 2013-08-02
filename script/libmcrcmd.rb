#!/usr/bin/ruby
require "libmcrdb"
require "libmcrrec"
require "libcommand"
require "libinssh"

module CIAX
  module Mcr
    class ExtCmd < Command
      def initialize(mdb,alist,procs)
        super()
        alist=type?(alist,App::List)
        type?(procs,Procs)
        procs[:getstat]=proc{|site| alist[site].stat}
        procs[:exec]=proc{|site,cmd| alist[site].exe(cmd) }
        self['sv']['ext']=ExtGrp.new(mdb,procs)
      end
    end

    class ExtGrp < ExtGrp
      def initialize(mdb,procs)
        super(mdb){}
        @mdb=type?(mdb,Mcr::Db)
        @procs=type?(procs,Procs)
        @def_proc=procs[:def_proc]
      end

      def setcmd(cmd)
        id,*par=type?(cmd,Array)
        @valid_keys.include?(id) || raise(InvalidCMD,list)
        ExtItem.new(@procs,@mdb,id,@def_proc).set_par(par)
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
        @record.interrupt
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
        mproc=Procs.new
        mproc[:submcr]=proc{|cmd,asy|
          mobj.setcmd(cmd).select
        }
        mobj=ExtCmd.new(mdb,al,mproc)
        mobj.setcmd(ARGV).new_rec.start
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
