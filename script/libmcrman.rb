#!/usr/bin/ruby
require "libsh"
require "libmcrlist"

module CIAX
  module Mcr
    def self.new(cfg=ConfExe.new)
      if $opt['l']
        $opt.delete('l')
        cfg['host']='localhost'
        ManSv.new(cfg)
        ManCl.new(cfg)
      elsif $opt['c'] || $opt['h']
        ManCl.new(cfg)
      elsif $opt['t']
        Man.new(cfg)
      else
        ManSv.new(cfg)
      end
    end

    class Man < Exe
      def initialize(cfg)
        db=type?(cfg[:db],Db)
        super('mcr',db['id'],Command.new(cfg))
        @mode='TEST'
        @cobj.add_ext
        @cobj.add_int
        lc=cfg[:list_class]||List
        @output=@list=lc.new(@cobj)
        @valid_pars=@cobj.intgrp.valid_pars
        @cobj.lodom.join_group(@list.jumpgrp)
        @post_exe_procs << proc{
          @valid_pars.replace(@list.keys)
        }
        # View Seq mode
        @smode=false
        ext_shell
      end

      private
      def ext_shell
        @current=@lastsize=0
        @prompt_proc=proc{
          ("[%d]" % @list.index)+optlist(@list.option)
        }
        @post_exe_procs << proc{
          @output=@smode ? @list.output : @list
        }
        @shell_input_proc=proc{|args|
          cmd=args[0]
          n=cmd.to_i
          if 0 < n && n <= @valid_pars.size
            @list.index=n
            []
          elsif @cobj.intgrp.key?(cmd)
            [cmd]+[@list.current_sid]
          else
            args
          end
        }
        super
        vg=@cobj.lodom.add_group('caption'=>"Change View Mode",'color' => 9)
        vg.add_item('lst',"List mode").set_proc{@smode=false;''}
        vg.add_item('seq',"Sequencer mode").set_proc{@smode=true;''}
        vg.add_item('vis',"Visual mode").set_proc{@output.vmode='v';''}
        vg.add_item('raw',"Raw mode").set_proc{@output.vmode='r';''}
        self
      end
    end

    class ManCl < Man
      def initialize(cfg)
        cfg[:list_class]=ClList
        super
        host=cfg['host']||@cobj.cfg[:db]['host']||'localhost'
        port=cfg['port']||@cobj.cfg[:db]['port']||55555
        @pre_exe_procs << proc{@list.upd}
        ext_client(host,port)
      end
    end

    class ManSv < Man
      def initialize(cfg)
        cfg[:list_class]=SvList
        cfg[:submcr_proc]=proc{|args,src| exe(args,src)}
        super
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
          mobj=@list.add_ent(ent).lastval
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
