#!/usr/bin/ruby
require "libmcrcmd"

module CIAX
  module Mcr
    class Sh < Exe
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

    class List < ShList
      attr_reader :total
      def initialize(alist=nil)
        if App::List === alist
          @alist=alist
        else
          @alist=App::List.new
        end
        super()
        mdb=Mcr::Db.new.set(ENV['PROJ']||'ciax')
        @swsgrp=Group.new({'caption'=>'Switch Macro','color'=>5,'column'=>2})
        @swsgrp.share[:def_proc]=proc{|item| throw(:sw_site,item.id)}
        @stat=Stat.new{|page,ms|
          @swsgrp.add_item(page,ms['stat'])
          self[page]=ms
          ms.cobj['sv']['ext']=@mobj['sv']['ext']
          ms.cobj['lo']['sws']=@swsgrp
        }
        @mobj=ExtCmd.new(mdb,@alist){|item| @stat.add_page(Sh.new(item))}
        # Init Macro Manager Page
        man=Exe.new('mcr',mdb['id']).ext_shell(@stat)
        man['stat']='Macro Manager'
        @stat.add_page(man)
        @swsgrp.add_dummy("1..",'Macro Process')
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
