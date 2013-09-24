#!/usr/bin/ruby
require "libsh"
require "libmcrcmd"

module CIAX
  module Mcr
    class Man < Exe
      def initialize
        proj=ENV['PROJ']||'ciax'
        mdb=Mcr::Db.new.set(proj)
        @list=List.new.ext_file(proj)
        super('mcr',mdb['id'],ExtCmd.new(mdb,App::List.new){|item|
                @list.data.update item.fork
              })
        eg=@cobj['sv']['ext']
        ig=@cobj['sv']['int']
        ig.update_items(eg.get[:cmdlist])
        ig.set[:def_proc]=proc{|item|
          n=item.par[0]||@list.data.keys.last
          if st=@list.data[n]
            if st[:stat] == 'query'
              st.cmd_que << item.id
              self['msg']=st.res_que.pop
            else
              self['msg']='IGNORE'
            end
          else
            self['msg']='ABSENT'
          end
        }
        ig.each{|k,v| v[:parameter]=[{:type => 'num',:default => nil}]}
        ig.add_item('clean','Clean macros').set[:def_proc]=proc{@list.clean}
        @cobj.int_proc=proc{|i| @list.data.each{|st| st.thread.raise(Interrupt)}}
        Thread.new{@list.save while eg.get[:save_que].pop}
        ext_shell(@list)
      end
    end

    class List < Datax
      def initialize
        super('macro',{},'procs')
        @caption='<<< '+Msg.color('Active Macros',2)+' >>>'
        @total=''
      end

      def clean
        @data.each{|key,st|
          @data.delete(key) unless st.thread.alive?
        }
        self
      end

      def to_s
        page=[@caption]
        @data.each{|key,st|
          title="[#{key}]"
          msg="#{st[:cid]} (#{st[:stat]})"
          msg << "[#{st[:option]}]?" if st[:option]
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
