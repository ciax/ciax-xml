#!/usr/bin/ruby
require "libmcrsh"

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
  end

  if __FILE__ == $0
    GetOpts.new
    begin
      il=Ins::Layer.new
      man=Mcr::List.new(il)
      man.shell
    rescue InvalidCMD
      $opt.usage
    end
  end
end
