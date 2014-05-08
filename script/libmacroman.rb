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
        ext_shell(@list,{:def => "[%s]"},@cobj.intgrp.parameter)
      end

      def exe(args)
        self['sid']=''
        super
      end
    end

    class Sv < Man
      def initialize(port=nil)
        super
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
        ig.add_item('clean','Clean macros').set_proc{
          if @list.clean
            igpar[:list].clean
            @list.save
            'ACCEPT'
          else
            'NOSID'
          end
        }
        # External Command Group
        @cobj.ext_proc{|ent|
          mobj=Macro.new(ent){|args| exe(args)}
          Thread.new{mobj.exe}
          @list.add(mobj)
          sid=mobj.record['sid']
          igpar[:default]=sid
          igpar[:list] << sid
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

    class List < Datax
      def initialize(proj,ver=0)
        super('macro',{},'procs')
        self['id']=proj
        self['ver']=ver
        @caption='<<< '+Msg.color('Active Macros',2)+' >>>'
      end

      def add(mobj)
        sid=type?(mobj,Macro).record['sid']
        @data[sid]=mobj
        self
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
