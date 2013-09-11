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

    class Stat < Datax
      def initialize
        super('macro',[],'procs')
        @caption='<<< '+Msg.color('Active Macros',2)+' >>>'
        @total=''
      end

      def add_page(ms)
        @data << ms
        ms.upd_proc << proc{save}
        set_prom(ms)
      end

      def set_prom(ms)
        page=@data.size.to_s
        ms.pdb['total']="[#{page}/%s]"
        @total.replace(page)
        ms['total']=@total
        ms
      end

      def to_s
        page=[@caption]
        num=0
        @data.each{|ms|
          cmd=ms['id']
          stat=ms['stat']
          tid=ms['tid']
          page << Msg.item("[#{num+=1}]","#{cmd} (#{stat}),#{tid}")
        }
        page.join("\n")
      end
    end

    class List < ShList
      def initialize
        proj=ENV['PROJ']||'ciax'
        mdb=Mcr::Db.new.set(proj)
        @stat=Stat.new.ext_file(proj)
        super{@stat.set_prom(Exe.new('mcr',mdb['id']).ext_shell(@stat))}
        @swsgrp=Group.new({'caption'=>'Switch Macro','color'=>5,'column'=>2})
        @swsgrp.share[:def_proc]=proc{|item| raise(SwSite,item[:cid])}
        @swsgrp.add_item('0','Macro Manager')
        @swsgrp.add_dummy('1..','Macro Process')
        @al=App::List.new
        @mobj=ExtCmd.new(mdb,@al){|item| add_page(@stat.add_page(Sh.new(item)))}
        # Init Macro Manager Page
        @init_proc << proc{|ms| ms.cobj['sv']['ext']=@mobj['sv']['ext']}
      end

      def add_page(ms)
        page=@stat.data.size
        self[page.to_s]=ms
        @swsgrp.add_item(page.to_s,ms['stat'])
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
