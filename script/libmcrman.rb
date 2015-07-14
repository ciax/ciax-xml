#!/usr/bin/ruby
require "libsh"
require "libmcrlist"

module CIAX
  module Mcr
    module Man
      def self.new(cfg=Config.new('mcr'))
        if $opt['l']
          $opt.delete('l')
          cfg['host']='localhost'
          Sv.new(cfg)
          Cl.new(cfg)
        elsif $opt['c'] || $opt['h']
          Cl.new(cfg)
        elsif $opt['t']
          Exe.new(cfg)
        else
          Sv.new(cfg)
        end
      end

      class Exe < CIAX::Exe
        # cfg should have [:jump_groups],[:sub_list](App::List)
        def initialize(cfg,attr={})
          proj=ENV['PROJ']||'ciax'
          type?(cfg,Config)
          super(proj,cfg)
          @output=@list=List.new(@cfg).ext_shell
          @cobj=Index.new(@cfg)
          @cobj.add_rem.add_hid
          @cobj.rem.add_ext(Db.new.get(proj))
          @cobj.rem.add_int
          @cfg[:submcr_proc]=proc{|args,id|
            @list.add(@cobj.set_cmd(args),id)
          }
          @valid_pars=@cobj.rem.int.valid_pars
          ext_shell
          @post_exe_procs << proc{
#            @valid_pars.replace(@list.keys)
          }
        end

        private
        def ext_shell
          super
          @current=@lastsize=0
#          @prompt_proc=proc{
#            ("[%d]" % @list.index)+optlist(@list.option)
#          }
          @post_exe_procs << proc{
            @output=@list.to_v
          }
#          @shell_input_proc=proc{|args| @list.conv_cmd(args,@cobj.intgrp)}
          vg=@cobj.loc.add_view
          vg.add_item('lst',"List mode").def_proc{@smode=false;''}
          vg.add_item('seq',"Sequencer mode").def_proc{@smode=true;''}
          vg.get('vis').def_proc{@output.vmode='v';''}
          vg.get('raw').def_proc{@output.vmode='r';''}
          self
        end
      end

      class Cl < Exe
        def initialize(cfg)
          cfg[:list_class]=ClList
          super
          host=cfg['host']||@cobj.cfg[:dbi]['host']||'localhost'
          port=cfg['port']||@cobj.cfg[:dbi]['port']||55555
          @pre_exe_procs << proc{@list.upd}
          ext_client(host,port)
        end
      end

      class Sv < Exe
        def initialize(cfg)
          cfg[:submcr_proc]=proc{|args,src| exe(args,src)}
          super
          port=cfg['port']||@cobj.rem.ext.cfg[:dbi]['port']||55555
          self['sid']='' # For server response
          @pre_exe_procs << proc{ self['sid']='' }
          # Internal Command Group
          @cobj.rem.int.def_proc{|ent|
            sid=ent.par[0]
            if seq=@list.get(sid)
              self['sid']=sid
              seq.reply(ent.id)
            else
              "NOSID"
            end
          }
          # External Command Group
          @cobj.rem.ext.def_proc{|ent|
            @list.add(ent).fork
            "ACCEPT"
          }
          @cobj.get('interrupt').def_proc{|ent|
            @list.interrupt
            'INTERRUPT'
          }
          ext_server(port)
        end
      end

      if __FILE__ == $0
        GetOpts.new('mnlrt')
        begin
          cfg=Config.new
          cfg[:jump_groups]=[]
          wl=Wat::List.new(cfg)
          cfg[:sub_list]=wl.cfg[:sub_list] #Take App List
          Man.new(cfg).shell
        rescue InvalidCMD
          $opt.usage("[mcr] [cmd] (par)")
        end
      end
    end
  end
end
