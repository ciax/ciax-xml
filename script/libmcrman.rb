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
        @list=lc.new(db['id'],db['version'])
        @valid_pars=@cobj.intgrp.valid_pars
        @mode='TEST'
        @current=0
        ext_shell(@list){
          size=@valid_pars.replace(@list.data.keys).size
          @current=size if size < @current || @current < 1
          "[%d]" % @current
        }
      end

      def shell_input(line)
        cmd,*par=super
        if @cobj.intgrp.key?(cmd)
          @current=par[0].to_i unless par.empty?
          par=[@list.sid_to_num(@current)]
        end
        [cmd]+par
      end
    end

    class ManCl < Man
      def initialize(cfg)
        super
        @mode='CL'
        host=cfg['host']||@cobj.cfg[:db]['host']||'localhost'
        port=cfg['port']||@cobj.cfg[:db]['port']||55555
        @list.ext_http(host)
        @pre_exe_procs << proc{@list.upd}
        ext_client(host,port)
      end
    end

    class List < Datax
      attr_accessor :current
      def initialize(proj,ver=0)
        super('macro',{},'procs')
        self['id']=proj
        self['ver']=ver
      end

      def get_obj(sid)
        @data[sid]
      end

      def sid_to_num(num) #convert the order number(Integer) to sid
        @data.keys[num-1]
      end

      def to_s
        idx=1
        page=['<<< '+Msg.color('Active Macros',2)+' >>>']
        @data.each{|key,mst|
          title="[#{idx}](#{key})"
          msg="#{mst['cid']} [#{mst['step']}/#{mst['total_steps']}](#{mst['stat']})"
          msg << "[#{mst['option']}]? " if mst['option']
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
        @mode='SV'
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
            if mobj['stat'] == 'query'
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
          mobj=Seq.new(ent){|args| exe(args)}
          @list.add(mobj)
          self['sid']=mobj.id
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
      def initialize(proj,ver=0)
        super
        @tgrp=ThreadGroup.new
      end

      def add(mobj)
        sid=type?(mobj,Seq).id
        @data[sid]=mobj
        mobj.post_stat_procs << proc{save}
        mobj.post_exe_procs << proc{|m|
          clean(m.id)
          save
        }
        @tgrp.add(mobj.fork)
        self
      end

      def clean(sid)
        @data.delete(sid)
        @data.keys.each{|id|
          @tgrp.list.any?{|t|
            id == t[:sid]
          }||@data.delete(id)
        }
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
