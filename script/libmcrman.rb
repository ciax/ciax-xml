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
        super('mcr',mdb['id'],ExtCmd.new(mdb,App::List.new))
        @cobj['sv']['ext'].set_proc{|ent|
          key,stat=ent.fork
          self['sid']=key
          @list.data[key]=stat
        }
        self['sid']=''
        @cobj.save_proc{@list.save}
        ig=@cobj.add_svgrp('int',IntGrp){|ent|
          n=ent.par[0]||@list.data.keys.last||""
          self['sid']=n
          if st=@list.data[n]
            if st[:stat] == 'query'
              st.cmd_que << ent.id
              self['msg']=st.res_que.pop
            else
              self['msg']='IGNORE'
            end
          else
            self['msg']='NONE'
          end
        }
        ig.each{|k,v| v[:parameter]=[{:type => 'num',:default => nil}]}
        ig.add_item('clean','Clean macros'){
          self['msg']='NONE' unless @list.clean
          @list.save
        }
        @cobj.int_proc=proc{|i|
          @list.data.each{|st|
            st.thread.raise(Interrupt)
          }
        }
        ext_shell(@list)
      end

      def exe(args)
        self['sid']=''
        super
      end

      def shell_output
        sid=self['sid'].empty? ? '' : '('+self['sid']+')'
        self['msg'].empty? ? @output : self['msg']+sid
      end
   end

    class List < Datax
      def initialize
        super('macro',{},'procs')
        @caption='<<< '+Msg.color('Active Macros',2)+' >>>'
        @total=''
      end

      def clean
        res=nil
        @data.each{|key,st|
          unless st.thread.alive?
            @data.delete(key)
            res=1
          end
        }
        res
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
