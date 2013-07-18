#!/usr/bin/ruby
require "libmcrexe"

module CIAX
  module Mcr
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
      def initialize(cobj,id,total='0')
        cobj=type?(cobj,ExtCmd)
        update({'layer'=>'mcr','id'=>id,'total'=>total})
        super(cobj)
        stat=Stat.new
        prom=Sh::Prompt.new(self,{'total'=>"[0/%s]"})
        ext_shell(stat,prom)
      end
    end

    class Sv < Exe
      # @< cobj,output,upd_proc*
      # @ al,appint,th,item,mobj*
      attr_reader :prompt,:th
      def initialize(mitem,il,&mcr_proc)
        super(mitem,il,&mcr_proc)
        @il=type?(il,Ins::Layer)
        @cobj=Command.new
        @upd_proc=UpdProc.new
        prom=Sh::Prompt.new(self,{'stat' => "(%s)"})
        ext_shell(@record,prom)
        ig=@cobj['sv']['int']
        ig.add_item('e','Execute Command').def_proc=proc{ ans('e') }
        ig.add_item('s','Skip Execution').def_proc=proc{ ans('s') }
        ig.add_item('d','Done Macro').def_proc=proc{ ans('d') }
        ig.add_item('f','Force Proceed').def_proc=proc{ ans('f') }
        ig.add_item('r','Retry Checking').def_proc=proc{ ans('r') }
        @th=Thread.new(ig.valid_keys.clear){|vk| start(vk) }
        @cobj.int_proc=proc{|i| @th.raise(Interrupt)}
        @th
      end

      def ans(str)
        return if @th.status != 'sleep'
        @th[:query]=str
        @th.run
      end
    end

    class List < Sh::List
      attr_reader :total
      def initialize(il,proj='ciax')
        @il=type?(il,Ins::Layer)
        mdb=Mcr::Db.new.set(proj)
        @mobj=ExtCmd.new(mdb)
        super('0')
        @total='0'
        @man=self['0']=Man.new(@mobj,mdb['id'],@total)
        @extgrp=@man.cobj['sv']['ext']
        @swgrp=@man.cobj['lo'].add_group('sw',"Switching Macro")
        @swgrp.add_item('0',"Macro Manager").def_proc=proc{throw(:sw_site,'0') }
        @swgrp.cmdlist["1.."]='Other Macro Process'
        @extgrp.def_proc=proc{|item| add_page(item)}
      end

      # item includes arbitrary mcr command
      # Sv generated and added to list in yield part as mcr command is invoked
      def add_page(item)
        @total.succ!
        page="#{@total}"
        msh=self[page]=Sv.new(item,@il){|cmd,asy|
          submcr=@mobj.setcmd(cmd) #submacro
          asy ? add_page(submcr) : submcr
        }
        @swgrp.add_item(page).def_proc=proc{throw(:sw_site,page)}
        msh.prompt['total']="[#{page}/%s]"
        msh.cobj['lo']['sw']=@swgrp
        msh.cobj['lo']['ext']=@extgrp
        msh['total']=@total
        @man.output.add(@total,item[:cmd],msh)
      end
    end

    if __FILE__ == $0
      GetOpts.new('rest',{'n' => 'nonstop mode'})
      begin
        il=Ins::Layer.new('app')
        mdb=Db.new.set('ciax')
        mobj=ExtCmd.new(mdb)
        mitem=mobj.setcmd(ARGV)
        msh=Sv.new(mitem,il){|cmd,asy|
          mobj.setcmd(cmd) unless asy
        }
        msh.shell
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
