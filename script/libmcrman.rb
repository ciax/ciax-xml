#!/usr/bin/ruby
require "libsh"
require "libmcrcmd"

module CIAX
  module Mcr
    class Man < Exe
      def initialize
        proj=ENV['PROJ']||'ciax'
        mdb=Mcr::Db.new.set(proj)
        @stat=Stat.new.ext_file(proj)
        super('mcr',mdb['id'],ExtCmd.new(mdb,App::List.new){|item|
                item.new_rec(self)
                @stat.add_proc(Thread.new{item.start})
              })
        ig=@cobj['sv']['int']
        ig.update_items(@cobj['sv']['ext'].get[:cmdlist])
        ig.set[:def_proc]=proc{|item|
          th=Thread.current
          if th.status == 'sleep'
            th[:query]=item.id
            th.run
          end

        }
        @cobj.int_proc=proc{|i| Threa.current.raise(Interrupt)}
        ext_shell(@stat,{'total' => nil,'stat' => "(%s)",'option' => nil})
      end
    end

    class Stat < Datax
      def initialize
        super('macro',ThreadGroup.new,'procs')
        @caption='<<< '+Msg.color('Active Macros',2)+' >>>'
        @total=''
      end

      def add_proc(th)
        @data.add(th)
        page=@data.list.size.to_s
        @total.replace(page)
        th['total']=@total
        th
      end

      def to_s
        page=[@caption]
        num=0
        @data.list.each{|th|
          cmd=th[:cid]
          stat=th[:stat]
          tid=th[:id]
          page << Msg.item("[#{num+=1}]","#{cmd} (#{stat}),#{tid}")
        }
        page.join("\n")
      end
    end

    if __FILE__ == $0
      GetOpts.new('rest',{'n' => 'nonstop mode'})
      begin
        Man.new.shell
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
