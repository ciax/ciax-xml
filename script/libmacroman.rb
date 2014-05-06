#!/usr/bin/ruby
require "libsh"
require "libmacroexe"

module CIAX
  module Mcr
    class Man < CIAX::Exe
      def initialize(port=nil)
        proj=ENV['PROJ']||'ciax'
        cfg=Config.new
        db=cfg[:db]=Mcr::Db.new.set(proj)
        cfg[:app]=App::List.new
        @list=List.new(proj).ext_file
        self['sid']='' # response id
        super('mcr',db['id'],Command.new(cfg))
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

    class Sv < Man
      def initialize(port=nil)
        super
        @cobj.ext_proc{|ent|
          mobj=Exe.new(@cobj).fork(ent)
          self['sid']=mobj.record['sid']
          @list.data[self['sid']]=mobj
          "ACCEPT"
        }
#        @cobj.save_procs{@list.save}
        @cobj.item_proc('interrupt'){|ent|
          @list.data.each{|st|
            st.thread.raise(Interrupt)
          }
          'INTERRUPT'
        }
        # Internal Command Group
        ig=@cobj.add_int(:valid_keys =>[])
        ig.set_proc{|ent|
          n=ent.par[0]||@list.data.keys.last||""
          self['sid']=n
          if st=@list.data[n]
            if st[:stat] == 'query'
              st.cmd_que << ent.id
              st.res_que.pop
            else
              "IGNORE"
            end
          else
            "NOSID"
          end
        }
        ig.each{|k,v| v[:parameter]=[{:type => 'num',:default => nil}]}
        ig.add_item('clean','Clean macros').set_proc{
          if @list.clean
            @list.save
            'ACCEPT'
          else
            'NOSID'
          end
        }
        ext_server(port||@cobj.cfg[:db]['port']||55555)
      end
    end

    class List < Datax
      def initialize(proj)
        super('macro',{},'procs')
        self['id']=proj
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
        Sv.new.shell
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
