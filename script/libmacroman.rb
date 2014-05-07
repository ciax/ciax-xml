#!/usr/bin/ruby
require "libsh"
require "libmacroexe"

module CIAX
  module Mcr
    class Man < Exe
      def initialize(port=nil)
        proj=ENV['PROJ']||'ciax'
        cfg=Config.new
        db=cfg[:db]=Mcr::Db.new.set(proj)
        cfg[:app]=App::List.new
        @list=List.new(proj,db['version']).ext_file
        self['sid']='' # For server response
        super('mcr',db['id'],Command.new(cfg))
        ext_shell(@list)
      end

      def exe(args)
        self['sid']=''
        super
      end
    end

    class Sv < Man
      def initialize(port=nil)
        super
        exe_que=Queue.new
        Thread.new{ loop{ exe(exe_que.pop) } }
        # Internal Command Group
        ig=@cobj.add_int
        ig.set_proc{|ent|
          n=ent.par[0]||""
          if mobj=@list.data[n]
            ig.parameter[:default]=n
            self['sid']=n
            if mobj[:stat] == 'query'
              mobj.que_cmd << ent.id
              mobj.que_res.pop
            else
              "IGNORE"
            end
          else
            "NOSID"
          end
        }
        ig.add_item('clean','Clean macros').set_proc{
          if @list.clean
            ig.parameter[:list].clean
            @list.save
            'ACCEPT'
          else
            'NOSID'
          end
        }
        # External Command Group
        @cobj.ext_proc{|ent|
          mobj=Macro.new(ent,exe_que).fork
          sid=mobj.record['sid']
          @list.data[sid]=mobj
          ig.parameter[:default]=sid
          ig.parameter[:list] << sid
          ig.valid_keys << sid
          self['sid']=sid
          "ACCEPT"
        }
        @cobj.item_proc('interrupt'){|ent|
          @list.data.each{|mobj|
            mobj.thread.raise(Interrupt)
          }
          'INTERRUPT'
        }
        @post_procs << proc{@list.save}
        ext_server(port||@cobj.cfg[:db]['port']||55555)
      end
    end

    class List < Datax
      def initialize(proj,ver=0)
        super('macro',{},'procs')
        self['id']=proj
        self['ver']=ver
        @caption='<<< '+Msg.color('Active Macros',2)+' >>>'
        @total=''
      end

      def clean
        res=nil
        @data.each{|key,mobj|
          unless mobj.thread.alive?
            @data.delete(key)
            res=1
          end
        }
        res
      end

      def to_s
        page=[@caption]
        @data.each{|key,mobj|
          title="[#{key}]"
          msg="#{mobj[:cid]} [#{mobj[:step]}/#{mobj.total}](#{mobj[:stat]})"
          msg << "[#{mobj[:option]}]?" if mobj[:option]
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
