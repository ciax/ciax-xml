#!/usr/bin/ruby
require "libsh"
require "libmcrlist"

module CIAX
  module Mcr
    module Man
      def self.new(inter_cfg=Config.new('mcr'))
        if $opt['l']
          $opt.delete('l')
          inter_cfg['host']='localhost'
          Sv.new(inter_cfg)
          Cl.new(inter_cfg)
        elsif $opt['c'] || $opt['h']
          Cl.new(inter_cfg)
        elsif $opt['t']
          Exe.new(inter_cfg)
        else
          Sv.new(inter_cfg)
        end
      end

      class Exe < Exe
        def initialize(inter_cfg)
          id=ENV['PROJ']||'ciax'
          type?(inter_cfg,Config)
          Wat::List.new(inter_cfg) unless inter_cfg.layers.key?(:wat)
          inter_cfg[:db]||=Db.new.set(id)
          super(id,inter_cfg)
          @cobj.add_extgrp
          @cobj.add_intgrp(Int)
          lc=inter_cfg[:list_class]||List
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
          @shell_input_proc=proc{|args| @list.conv_cmd(args,@cobj.intgrp)}
          super
          vg=@cobj.lodom.add_group('caption'=>"Change View Mode",'color' => 9)
          vg.add_item('lst',"List mode").set_proc{@smode=false;''}
          vg.add_item('seq',"Sequencer mode").set_proc{@smode=true;''}
          vg.add_item('vis',"Visual mode").set_proc{@output.vmode='v';''}
          vg.add_item('raw',"Raw mode").set_proc{@output.vmode='r';''}
          self
        end
      end

      class Cl < Exe
        def initialize(inter_cfg)
          inter_cfg[:list_class]=ClList
          super
          host=inter_cfg['host']||@cobj.cfg[:db]['host']||'localhost'
          port=inter_cfg['port']||@cobj.cfg[:db]['port']||55555
          @pre_exe_procs << proc{@list.upd}
          ext_client(host,port)
        end
      end

      class Sv < Exe
        def initialize(inter_cfg)
          inter_cfg[:list_class]=SvList
          inter_cfg[:submcr_proc]=proc{|args,src| exe(args,src)}
          super
          port=inter_cfg['port']||@cobj.cfg[:db]['port']||55555
          self['sid']='' # For server response
          @pre_exe_procs << proc{ self['sid']='' }
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
          Man.new.shell
        rescue InvalidCMD
          $opt.usage("[mcr] [cmd] (par)")
        end
      end
    end
  end
end
