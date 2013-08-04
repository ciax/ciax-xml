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

      def add(num,msh)
        self[num]=msh
        self
      end

      def to_s
        page=[@caption]
        each{|key,msh|
          cmd=msh['id']
          stat=msh['stat']
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
        @mobj=ExtCmd.new(mdb,@alist){|item| add_page(Sv.new(item)) }
        @mobj['sv']['ext'].procs[:def_proc]=proc{|item| add_page(Sv.new(item))}
        @swmgrp=@mobj['lo'].add_group('swm',"Switching Macro")
        @swmgrp.cmdlist["1.."]='Other Macro Process'
        @total='/'
        msh=Man.new(@mobj,mdb['id'])
        add_page(msh,"Macro Manager")
      end

      # item includes arbitrary mcr command
      # Sv generated and added to list in yield part as mcr command is invoked
      def add_page(msh,title=nil)
        page="#{@total.succ!}"
        self[page]=msh
        @swmgrp.add_item(page,title).procs[:def_proc]=proc{throw(:sw_site,page)}
        msh.cobj['lo']['ext']=@mobj['sv']['ext']
        msh.cobj['lo']['swm']=@swmgrp
        msh.cobj['lo']['swl']=@swlgrp if @swlgrp
        msh.prompt['total']="[#{page}/%s]"
        msh['total']=@total
        self['0'].stat.add(page,msh) if page > "0"
        nil
      end
    end

    if __FILE__ == $0
      GetOpts.new('rest',{'n' => 'nonstop mode'})
      begin
        al=App::List.new
        mdb=Db.new.set('ciax')
        mobj=ExtCmd.new(mdb,al)
        mitem=mobj.setcmd(ARGV)
        msh=Sv.new(mitem)
        msh.shell
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
