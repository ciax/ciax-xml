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
        super('mcr',db['id'],Command.new(cfg))
        @cobj.add_int
        @list=List.new(proj,db['version'],@cobj.intgrp.parameter)
        ext_shell(@list){
          "[%s]" % @list.current_idx
        }
      end

      def shell_input(line)
        cmd,*par=super
        if @cobj.intgrp.key?(cmd)
          par.map!{|i|
            @list.data.keys[i.to_i]||i
          }
        end
        [cmd]+par
      end
    end

    class Sv < Man
      def initialize(port=nil)
        super
        self['sid']='' # For server response
        @pre_procs << proc{ self['sid']='' }
        @list.ext_file
        # Internal Command Group
        ig=@cobj.intgrp
        igpar=ig.parameter
        ig.set_proc{|ent|
          sid=ent.par[0]||""
          if mobj=@list.get(sid)
            self['sid']=sid
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
        # External Command Group
        @cobj.ext_proc{|ent|
          mobj=Macro.new(ent){|args| exe(args)}
          @list.add(mobj)
          self['sid']=mobj.sid
          "ACCEPT"
        }
        @cobj.item_proc('interrupt'){|ent|
          @list.interrupt
          'INTERRUPT'
        }
        ext_server(port||@cobj.cfg[:db]['port']||55555)
      end
    end

    class List < Datax
      def initialize(proj,ver=0,parameter={:list =>[],:default =>''})
        super('macro',{},'procs')
        self['id']=proj
        self['ver']=ver
        @parameter=parameter
        self['current']=parameter[:default]
        @caption='<<< '+Msg.color('Active Macros',2)+' >>>'
        @tgrp=ThreadGroup.new
      end

      def get(sid)
        setdef(sid) if mobj=@data[sid]
        mobj
      end

      def current_idx #convert sid to the order number(Integer)
        @data.keys.index(self['current'])
      end

      def setdef(sid)
        self['current']=@parameter[:default]=sid
      end

      def add(mobj)
        sid=type?(mobj,Macro).sid
        @data[sid]=mobj
        setdef(sid)
        @parameter[:list] << sid
        mobj.record.save_procs << proc{save}
        mobj.post_procs << proc{|m|
          @data.delete(m.sid)
          @parameter[:list]=@data.keys
          setdef(@data.keys.last)
          save
        }
        @tgrp.add(Thread.new{mobj.exe})
        self
      end

      def interrupt
        @tgrp.list.each{|t|
          t.raise(Interrupt)
        }
        self
      end

      def to_s
        page=[@caption]
        idx=0
        @data.each{|key,mobj|
          title="[#{idx}](#{key})"
          msg="#{mobj[:cid]} [#{mobj[:step]}/#{mobj.total}](#{mobj[:stat]})"
          msg << "[#{mobj[:option]}]?" if mobj[:option]
          page << Msg.item(title,msg)
          idx+=1
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
