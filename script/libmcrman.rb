#!/usr/bin/ruby
require "libsh"
require "libmcrexe"

module CIAX
  module Mcr
    class Man < Exe
      def initialize(port=nil,list_class=List)
        proj=ENV['PROJ']||'ciax'
        cfg=Config.new
        db=cfg[:db]=Mcr::Db.new.set(proj)
        cfg[:app]=App::List.new
        super('mcr',db['id'],Command.new(cfg))
        @cobj.add_int
        @current=0
        @list=list_class.new(proj,db['version'],@cobj.intgrp.valid_pars)
        ext_shell(@list){
          "[%d]" % @current
        }
      end

      def shell_input(line)
        cmd,*par=super
        if @cobj.intgrp.key?(cmd)
          if par.empty?
            par=[@list.get_sid(@current)]
          else
            par.map!{|i|
              @list.get_sid(i.to_i)||i
            }
            @current=@list.get_idx(par.first)||0
          end
        end
        [cmd]+par
      end
    end

    class List < Datax
      def initialize(proj,ver=0,valid_pars=[])
        super('macro',{},'procs')
        self['id']=proj
        self['ver']=ver
        @valid_pars=valid_pars
        @caption='<<< '+Msg.color('Active Macros',2)+' >>>'
        @current
      end

      def get_obj(sid)
        @data[sid]
      end

      def get_sid(num)
        @data.keys[num]
      end

      def get_idx(sid) #convert sid to the order number(Integer)
        @data.keys.index(sid)
      end

      def to_s
        page=[@caption]
        idx=0
        @data.each{|key,mst|
          title="[#{idx}](#{key})"
          msg="#{mst[:cid]} [#{mst[:step]}/#{mst.total}](#{mst[:stat]})"
          msg << "[#{mst[:option]}]?" if mst[:option]
          page << Msg.item(title,msg)
          idx+=1
        }
        page.join("\n")
      end
    end

    class Sv < Man
      def initialize(port=nil)
        super(port,SvList)
        self['sid']='' # For server response
        @pre_procs << proc{ self['sid']='' }
        @list.ext_file
        # Internal Command Group
        ig=@cobj.intgrp
        ig.set_proc{|ent|
          sid=ent.par[0]||""
          if mobj=@list.get_obj(sid)
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

    class SvList < List
      def initialize(proj,ver=0,valid_pars=[])
        super
        @tgrp=ThreadGroup.new
      end

      def add(mobj)
        sid=type?(mobj,Macro).sid
        @data[sid]=mobj
        @valid_pars << sid
        mobj.record.save_procs << proc{save}
        mobj.post_procs << proc{|m|
          @data.delete(m.sid)
          @valid_pars.replace(@data.keys)
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
