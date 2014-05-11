#!/usr/bin/ruby
require "libsh"
require "libmcrexe"

module CIAX
  module Mcr
    def self.new(cfg=Config.new)
      cfg[:db]||=Mcr::Db.new.set(ENV['PROJ']||'ciax')
      cfg[:app]||=App::List.new
      if $opt['t']
        Man.new(cfg)
      else
        if $opt['l']
          cfg['host']='localhost'
          ManSv.new(cfg)
          ManCl.new(cfg)
        else
          ManSv.new(cfg)
        end
      end
    end

    class Man < Exe
      def initialize(cfg)
        db=type?(cfg[:db],Db)
        super('mcr',db['id'],Command.new(cfg))
        @cobj.add_int
        lc=cfg[:list_class]||List
        @list=lc.new(db['id'],db['version'],@cobj.intgrp.valid_pars)
        @post_exe_procs << proc{@list.upd}
        ext_shell(@list){ "[%d]" % @list.current }
      end

      def shell_input(line)
        cmd,*par=super
        if @cobj.intgrp.key?(cmd)
          @list.current=par[0].to_i unless par.empty?
          par=[@list.current_sid]
        end
        [cmd]+par
      end
    end

    class ManCl < Man
      def initialize(cfg)
        super
        host=cfg['host']||@cobj.cfg[:db]['host']||'localhost'
        port=cfg['port']||@cobj.cfg[:db]['port']||55555
        @list.ext_http(host)
        @pre_exe_procs << proc{@list.upd}
        ext_client(host,port)
      end
    end

    class List < Datax
      attr_accessor :current
      def initialize(proj,ver=0,valid_pars=[])
        super('macro',{},'procs')
        self['id']=proj
        self['ver']=ver
        @valid_pars=valid_pars
        @current=0
        @post_upd_procs << proc{
          size=@valid_pars.replace(@data.keys).size
          @current=size if size < @current || @current < 1
        }
      end

      def get_obj(sid)
        @data[sid]
      end

      def current_sid #convert the order number(Integer) to sid
        @data.keys[@current-1]
      end

      def to_s
        idx=1
        page=['<<< '+Msg.color('Active Macros',2)+' >>>']
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

    class ManSv < Man
      def initialize(cfg)
        cfg[:list_class]=SvList
        super
        type?(cfg[:app],App::List)
        port=cfg['port']||@cobj.cfg[:db]['port']||55555
        self['sid']='' # For server response
        @pre_exe_procs << proc{ self['sid']='' }
        @list.ext_file
        # Internal Command Group
        @cobj.intgrp.set_proc{|ent|
          sid=ent.par[0]
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
        ext_server(port)
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
        mobj.record.post_upd_procs << proc{save}
        mobj.post_exe_procs << proc{|m|
          @data.delete(m.sid)
          save
        }
        @tgrp.add(Threadx.new("Macro Thread(#{sid})",12){mobj.exe})
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
      GetOpts.new('mnlrt')
      begin
        Mcr.new.shell
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
