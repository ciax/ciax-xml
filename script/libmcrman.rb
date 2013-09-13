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
        thg=@stat.data
        super('mcr',mdb['id'],ExtCmd.new(mdb,App::List.new){|item|
                item.new_rec
                @stat.data.add(Thread.new{item.start;sleep})
              })
        ig=@cobj['sv']['int']
        ig.update_items(@cobj['sv']['ext'].get[:cmdlist])
        ig.set[:def_proc]=proc{|item|
          n=item.par[0].to_i
          if th=thg.list[n]
            if th.status == 'sleep'
              th[:query]=item.id
              th.run
            end
          end
        }
        @cobj.int_proc=proc{|i| thg.list.each{|th| th.raise(Interrupt)}}
        ext_shell(@stat)
      end
    end

    class Stat < Datax
      def initialize
        super('macro',ThreadGroup.new,'procs')
        @caption='<<< '+Msg.color('Active Macros',2)+' >>>'
        @total=''
      end

      def to_s
        page=[@caption]
        @data.list.each_with_index{|th,i|
          title="[#{i}] (#{th[:id]})"
          msg="#{th[:cid]} (#{th[:stat]})"
          msg << "[#{th[:option]}]?" if th[:option]
          page << Msg.item(title,msg)
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
