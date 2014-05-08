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
        @list=List.new(proj,db['version'])
        super('mcr',db['id'],Command.new(cfg))
        ext_shell(@list){
          "[%s]" % @list.current
        }
      end

      def shell_input(line)
        cmd,*par=super
        if @cobj.intgrp.keys.include?(cmd)
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
        @list.ext_file
        # Internal Command Group
        ig=@cobj.intgrp
        igpar=ig.parameter
        ig.set_proc{|ent|
          sid=ent.par[0]||""
          if mobj=@list.data[sid]
            igpar[:default]=sid
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
          sid=mobj.record['sid']
          igpar[:default]=sid
          igpar[:list] << sid
          self['sid']=sid
          "ACCEPT"
        }
        @cobj.item_proc('interrupt'){|ent|
          @list.interrupt
          'INTERRUPT'
        }
        ext_server(port||@cobj.cfg[:db]['port']||55555)
      end

      def exe(args)
        self['sid']=''
        super
      end

    end

    class List < Datax
      attr_accessor :par
      def initialize(proj,ver=0)
        super('macro',{},'procs')
        self['id']=proj
        self['ver']=ver
        self['current']=''
        @caption='<<< '+Msg.color('Active Macros',2)+' >>>'
        @tgrp=ThreadGroup.new
      end

      def current #convert sid to order
        @data.keys.index(self['current'])
      end

      def add(mobj)
        sid=type?(mobj,Macro).record['sid']
        @data[sid]=mobj
        mobj.record.save_procs << proc{save}
        mobj.post_procs << proc{|m| @data.delete(m.sid)}
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
