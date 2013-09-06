#!/usr/bin/ruby
require "libsh"
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
        self['tid']=mitem.record['id']
        @cobj.int_proc=proc{|i| @th.raise(Interrupt)}
        ext_shell(mitem.record,{'total' => nil,'stat' => "(%s)",'option' => nil})
      end

      def to_s
        self['id']+'('+self['stat']+')'
      end
    end

    class Stat < Hashx
      def initialize
        @caption='<<< '+Msg.color('Active Macros',2)+' >>>'
        @total='/'
      end

      def add_page(ms)
        page="#{@total.succ!}"
        self[page]=ms
        ms.pdb['total']="[#{page}/%s]"
        ms['total']=@total
        page
      end

      def to_s
        page=[@caption]
        each{|key,ms|
          cmd=ms['id']
          stat=ms['stat']
          tid=ms['tid']
          page << Msg.item("[#{key}]","#{cmd} (#{stat}),#{tid}")
        }
        page.join("\n")
      end
    end

    class List < ShList
      attr_reader :total
      def initialize
        mdb=Mcr::Db.new.set(ENV['PROJ']||'ciax')
        super
        @stat=Stat.new
        @swsgrp=Group.new({'caption'=>'Switch Macro','color'=>5,'column'=>2})
        @swsgrp.share[:def_proc]=proc{|item| raise(SwSite,item[:cid])}
        @swsgrp.add_dummy("1..",'Macro Process')
        @al=App::List.new
        @mobj=ExtCmd.new(mdb,@al){|item| add_page(Sh.new(item))}
        @init_proc << proc{|ms| ms.cobj['sv']['ext']=@mobj['sv']['ext']}
        # Init Macro Manager Page
        man=Exe.new('mcr',mdb['id']).ext_shell(@stat)
        man['stat']='Macro Manager'
        add_page(man)
      end

      def add_page(ms)
        page=@stat.add_page(ms)
        @swsgrp.add_item(page,ms['stat'])
        self[page]=ms
        @init_proc.each{|p| p.call(ms)}
        self
      end
    end

    if __FILE__ == $0
      GetOpts.new('rest',{'n' => 'nonstop mode'})
      begin
        al=App::List.new
        mdb=Db.new.set('ciax')
        mobj=ExtCmd.new(mdb,al)
        mitem=mobj.setcmd(ARGV)
        msh=Sh.new(mitem)
        msh.shell
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
