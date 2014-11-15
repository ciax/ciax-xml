#!/usr/bin/ruby
require "libsh"
require "libmcrlist"

module CIAX
  module Mcr
    def self.new(cfg=Config.new('mcr'))
      cfg[:db]||=Mcr::Db.new.set(ENV['PROJ']||'ciax')
      cfg[:wat_list]||=Wat::List.new
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
        @cobj.add_ext
        @cobj.add_int
        lc=cfg[:list_class]||List
        @output=@list=lc.new(db['id'],db['version'])
        @valid_pars=@cobj.intgrp.valid_pars
        @mode='TEST'
      end

      def ext_shell
        @shell_input_proc=proc{|line|
          cmd,*par=line.split(' ')
          if @cobj.intgrp.key?(cmd)
            @current=par[0].to_i unless par.empty?
            par=[@list.num_to_sid(@current)]
          end
          [cmd]+par
        }
        @current=0
        super{
          size=@valid_pars.replace(@list.data.keys).size
          @current=size if size < @current || @current < 1
          "[%d]" % @current
        }
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

    class ManSv < Man
      def initialize(cfg)
        cfg[:list_class]=SvList
        cfg[:submcr_proc]=proc{|args| exe(args)}
        super
        @mode='SV'
        type?(cfg[:wat_list],Wat::List)
        port=cfg['port']||@cobj.cfg[:db]['port']||55555
        self['sid']='' # For server response
        @pre_exe_procs << proc{ self['sid']='' }
        @list.ext_file.clean
        # Internal Command Group
        @cobj.intgrp.set_proc{|ent|
          sid=ent.par[0]
          if sobj=@list.get_obj(sid)
            self['sid']=sid
            sobj.reply(ent.id)
          else
            "NOSID"
          end
        }
        # External Command Group
        @cobj.ext_proc{|ent|
          self['sid']=@list.add(ent).sid
          "ACCEPT"
        }
        @cobj.item_proc('interrupt'){|ent|
          @list.interrupt
          'INTERRUPT'
        }
        ext_server(port)
      end
    end

    if __FILE__ == $0
      GetOpts.new('mnlrt')
      begin
        Mcr.new.ext_shell.shell
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
