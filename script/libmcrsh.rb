#!/usr/bin/ruby
require "libmcrcmd"

module CIAX
  module Mcr
    class Sv < Sh::Exe
      attr_reader :th
      def initialize(mitem)
        super(Command.new)
        self['layer']='mcr'
        self['id']=mitem[:cid]
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
      def initialize(id,stat)
        super(Command.new)
        self['layer']='mcr'
        self['id']=id
        ext_shell(type?(stat,Stat))
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
        @mobj=ExtCmd.new(mdb,@alist)
        @swg=@mobj['lo'].add_group('swm',"Switching Macro")
        @mobj['sv']['ext'].share[:def_proc]=proc{|item| add_page(Sv.new(item))}
        @stat=Stat.new
        msh=Man.new(mdb['id'],@stat)
        add_page(msh)
        @swg.cmdlist["0"]='Macro Manager'
        @swg.cmdlist["1.."]='Other Macro Process'
      end

      # item includes arbitrary mcr command
      # Sv generated and added to list in yield part as mcr command is invoked
      def add_page(msh)
        page="#{@total.succ!}"
        self[page]=msh
        @mobj.each{|k,v| msh.cobj[k].update v}
        msh.cobj['lo']['swm'].add_item(page).share[:def_proc]=proc{throw(:sw_site,page)}
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
