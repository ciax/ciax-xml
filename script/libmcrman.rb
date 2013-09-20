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
                @stat.data.update item.fork
              })
        eg=@cobj['sv']['ext']
        ig=@cobj['sv']['int']
        ig.update_items(eg.get[:cmdlist])
        ig.set[:def_proc]=proc{|item|
          n=item.par[0]||@stat.data.keys.last
          if th=@stat.data[n]
            th[:queue] << item.id if th.status == 'sleep'
          else
            self['msg']='ABSENT'
          end
        }
        ig.add_item('clean','Clean macros').set[:def_proc]=proc{@stat.clean}
        @cobj.int_proc=proc{|i| @stat.data.each{|th| th.raise(Interrupt)}}
        trig=eg.get[:stat_trig]
        Thread.new{@stat.save while trig.pop}
        ext_shell(@stat)
      end
    end

    class Stat < Datax
      def initialize
        super('macro',{},'procs')
        @caption='<<< '+Msg.color('Active Macros',2)+' >>>'
        @total=''
      end

      def clean
        @data.each{|key,th|
          @data.delete(key) unless th.alive?
        }
        self
      end

      def to_s
        page=[@caption]
        @data.each{|key,th|
          title="[#{key}]"
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
