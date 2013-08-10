#!/usr/bin/ruby
require "libmcrcmd"

module CIAX
  module Mcr
    class Sv < Exe
      attr_reader :th
      def initialize(mitem)
        super('mcr',mitem[:cid])
        ig=@cobj['sv']['int']
        ig.update_items(mitem.shary[:cmdlist])
        ig.share[:def_proc]=proc{|item|
          if @th.status == 'sleep'
            @th[:query]=item.id
            @th.run
          end
        }
        mitem.new_rec(self,ig.valid_keys)
        @th=Thread.new{ mitem.start }
        @cobj.int_proc=proc{|i| @th.raise(Interrupt)}
        ext_shell(mitem.record,{'total' => nil,'stat' => "(%s)",'option' => nil})
      end

      def to_s
        self['id']+'('+self['stat']+')'
      end
    end

    class Stat < Hashx
      def initialize(&page_proc)
        @caption='<<< '+Msg.color('Active Macros',2)+' >>>'
        @total='/'
        @page_proc=page_proc
      end

      def add_page(ms)
        page="#{@total.succ!}"
        self[page]=ms
        ms.pdb['total']="[#{page}/%s]"
        ms['total']=@total
        @page_proc.call(page,ms) if @page_proc
        ms
      end

      def to_s
        page=[@caption]
        each{|key,ms|
          cmd=ms['id']
          stat=ms['stat']
          page << Msg.item("[#{key}]","#{cmd} (#{stat})")
        }
        page.join("\n")
      end
    end

    class Man < ShList
      attr_reader :total
      def initialize(alist=nil)
        if App::List === alist
          @alist=alist
        else
          @alist=App::List.new
        end
        super({'0'=>'Macro Manager',"1.."=>'Macro Process'})
        mdb=Mcr::Db.new.set(ENV['PROJ']||'ciax')
        @stat=Stat.new{|page,ms|
          self[page]=initexe(ms)
          @swsgrp.add_item(page)
        }
        @mobj=ExtCmd.new(mdb,@alist){|item| @stat.add_page(Sv.new(item))}
        # Init Macro Manager Page
        man=self['0']=Exe.new('mcr',mdb['id']).ext_shell(@stat)
        man['stat']='Macro Manager'
        @stat.add_page(man)
      end

      def initexe(mex)
        mex.cobj['sv']['ext']=@mobj['sv']['ext']
        super
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
