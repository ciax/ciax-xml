#!/usr/bin/ruby
require "libsh"
require "libmcrlist"

module CIAX
  module Mcr
    def self.new(cfg=ConfExe.new)
      if $opt['t']
        Man.new(cfg)
      elsif $opt['c'] || $opt['h']
        ManCl.new(cfg)
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
        @output=@list=lc.new(@cobj)
        @valid_pars=@cobj.intgrp.valid_pars
        @cobj.lodom.join_group(@list.jumpgrp)
        @mode='TEST'
      end

      def ext_shell
        @prompt_proc=proc{
          size=@valid_pars.replace(@list.keys).size
          @current=size if size < @current || @current < 1
          "[%d]" % @current
        }
        @shell_input_proc=proc{|args|
          cmd=args[0]
          if (n=cmd.to_i) > 0
            @current=n
            []
          elsif @cobj.intgrp.key?(cmd)
            [cmd]+[@list.num_to_sid(@current)]
          else
            args
          end
        }
        @current=0
        super
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
        cfg[:submcr_proc]=proc{|args,src| exe(args,src)}
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
          if sobj=@list.get(sid)
            self['sid']=sid
            sobj.reply(ent.id)
          else
            "NOSID"
          end
        }
        # External Command Group
        @cobj.ext_proc{|ent|
          self['sid']=@list.add_ent(ent).lastval.id
          @current=@list.size
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
