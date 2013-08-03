#!/usr/bin/ruby
require "libmcrcmd"

module CIAX
  module Mcr
    class Sv < Sh::Exe
      attr_reader :prompt,:th
      def initialize(mitem)
        super(Command.new)
        self['layer']='mcr'
        self['id']=mitem[:cmd]
        ig=@cobj['sv']['int']
        ig.add_item('e','Execute Command').procs[:def_proc]=proc{ ans('e') }
        ig.add_item('s','Skip Execution').procs[:def_proc]=proc{ ans('s') }
        ig.add_item('d','Done Macro').procs[:def_proc]=proc{ ans('d') }
        ig.add_item('f','Force Proceed').procs[:def_proc]=proc{ ans('f') }
        ig.add_item('r','Retry Checking').procs[:def_proc]=proc{ ans('r') }
        mitem.new_rec(self,ig.valid_keys.clear)
        @th=Thread.new{ mitem.start }
        @cobj.int_proc=proc{|i| @th.raise(Interrupt)}
        prom=Sh::Prompt.new(self,{'stat' => "(%s)"})
        ext_shell(mitem.record,prom)
      end

      def ans(str)
        return if @th.status != 'sleep'
        @th[:query]=str
        @th.run
      end

      def to_s
        self['id']+'('+self['stat']+')'
      end
    end

    class Stat < ExHash
      def initialize
        @caption='<<< '+Msg.color('Active Macros',2)+' >>>'
      end

      def add(num,cmd,mexe)
        self[num]=[cmd,mexe]
        self
      end

      def to_s
        page=[@caption]
        each{|key,ary|
          cmd=ary[0]
          stat=ary[1]['stat']
          page << Msg.item("[#{key}]","#{cmd} (#{stat})")
        }
        page.join("\n")
      end
    end

    class Man < Sh::Exe
      attr_reader :prompt,:stat
      def initialize(cobj,id)
        super(cobj)
        self['layer']='mcr'
        self['id']=id
        @stat=Stat.new
        ext_shell(@stat,Sh::Prompt.new(self))
      end
    end

    class List < Sh::List
      attr_reader :total
      def initialize(alist=nil)
        super()
        if App::List === alist
          @alist=alist
        else
          @alist=App::List.new
        end
        mdb=Mcr::Db.new.set(ENV['PROJ']||'ciax')
        @mproc=Procs.new
        @mproc[:def_proc]=proc{|item| add_page(item)}
        @mproc[:submcr]=proc{|cmd,asy|
          item=@mobj.setcmd(cmd)
          if asy
            add_page(item)
          else
            item.select
          end
        }
        @mobj=ExtCmd.new(mdb,@alist,@mproc)
        @swmgrp=@mobj['lo'].add_group('swm',"Switching Macro")
        @swmgrp.cmdlist["1.."]='Other Macro Process'
        first_page(mdb['id'])
      end

      def first_page(id)
        @total='0'
        msh=self['0']=Man.new(@mobj,id)
        @swmgrp.add_item('0',"Macro Manager").procs[:def_proc]=proc{throw(:sw_site,'0') }
        @mobj['lo']['swl']=@swlgrp if @swlgrp
        msh['total']=@total
        msh.prompt['total']="[#{@total}/%s]"
      end

      # item includes arbitrary mcr command
      # Sv generated and added to list in yield part as mcr command is invoked
      def add_page(item)
        @total.succ!
        page="#{@total}"
        msh=self[page]=Sv.new(item)
        @swmgrp.add_item(page).procs[:def_proc]=proc{throw(:sw_site,page)}
        msh.cobj['lo']['ext']=@mobj['sv']['ext']
        msh.cobj['lo']['swm']=@swmgrp
        msh.cobj['lo']['swl']=@swlgrp if @swlgrp
        msh['total']=@total
        msh.prompt['total']="[#{page}/%s]"
        self['0'].stat.add(@total,item[:cmd],msh)
        nil
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
        mitem=mobj.setcmd(ARGV)
        msh=Sv.new(mitem)
        msh.shell
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
