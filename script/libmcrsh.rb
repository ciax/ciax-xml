#!/usr/bin/ruby
require "libmcrcmd"

module CIAX
  module Mcr
    class Sv < Sh::Exe
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
        ext_shell(mitem.record,{'total' => nil,'stat' => "(%s)",'opt' => nil})
      end

      def to_s
        self['id']+'('+self['stat']+')'
      end
    end

    class Stat < Hashx
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
        @total='/'
        @stat=Stat.new
        @mobj=ExtCmd.new(mdb,@alist){|item| add_page(Sv.new(item))}
        @swm=@mobj['lo'].add_group('swm',"Switching Macro")
        add_page(Sh::Exe.new('mcr',mdb['id']).ext_shell(@stat),'Macro Manager')
        @swm.cmdlist["1.."]='Other Macro Process'
      end

      # item includes arbitrary mcr command
      # Sv generated and added to list in yield part as mcr command is invoked
      def add_page(msh,title=nil)
        page="#{@total.succ!}"
        self[page]=msh
        @swm.add_item(page,title).share[:def_proc]=proc{throw(:sw_site,page)}
        msh.cobj['sv']['ext']=@mobj['sv']['ext']
        msh.cobj['lo']['swm']=@swm
        msh.pdb['total']="[#{page}/%s]"
        msh['total']=@total
        @stat.add(page,msh) if page > "0"
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
