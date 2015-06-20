#!/usr/bin/ruby
require "libsitelist"
require "libwatview"
require "libapplist"

module CIAX
  $layers['w']=Wat
  module Wat
    def self.new(id,inter_cfg={},attr={})
      Msg.type?(attr,Hash)

      if $opt.delete('l')
        attr['host']='localhost'
        Sv.new(id,inter_cfg,attr)
      elsif host=$opt['h']
        attr['host']=host
      elsif $opt['c']
      elsif $opt['s'] or $opt['e']
        return Sv.new(id,inter_cfg,attr)
      else
        return Test.new(id,inter_cfg,attr)
      end
      Cl.new(id,inter_cfg,attr)
    end

    # inter_cfg should have 'id',layer[:app]
    class Exe < Exe
      attr_reader :ash
      def initialize(id,inter_cfg={},attr={})
        @cls_color=3
        super
        @site_stat.add_db('auto'=>'@','watch'=>'&')
        @ash=@cfg.layers[:app].get(@id)
        @cobj.add_rem(@ash)
        @event=Event.new.set_db(@ash.adb)
        @wview=View.new(@ash.adb,@event)
        @ash.batch_interrupt=@event.get('int')
        @output=$opt['j']?@event:@wview
      end

      def init_sv
        @mode=@ash.mode
        @event.post_upd_procs << proc{upd}
        @ash.stat.post_upd_procs << proc{
          verbose("Watch","Propagate Status#upd -> Event#upd")
        }
        @ash.pre_exe_procs << proc{|args| @event.block?(args) }
        @event.ext_rsp(@ash.stat)
      end

      def upd
        @site_stat['watch'] = @event.active?
        block=@event.get('block').map{|id,par| par ? nil : id}.compact
        @cobj.rem.ext.valid_sub(block)
        verbose("Watch","Propagate Event#upd -> Watch::Exe#upd")
        self
      end

      def ext_shell
        super
        vg=@cobj.loc.add('caption'=>"Change View Mode",'color' => 9,'column' => 2)
        vg.add_item('vis',"Visual mode").cfg.proc{@output=@wview;''}
        vg.add_item('raw',"Raw Print mode").cfg.proc{@output=@event;''}
        self
      end
    end

    class Test < Exe
      def initialize(id,inter_cfg={},attr={})
        super
        init_sv
        # @event is independent from @ash.stat
        @ash.stat.post_upd_procs << proc{@event.upd}
      end
    end

    class Cl < Exe
      def initialize(id,inter_cfg={},attr={})
        super
        @event.ext_http(@ash.host)
        # @event is independent from @ash.stat
        @pre_exe_procs << proc{@event.upd}
      end
    end

    class Sv < Exe
      def initialize(id,inter_cfg={},attr={})
        super
        init_sv
        @event.ext_file
        @event.def_proc=proc{|args,src,pri|
          @ash.exe(args,src,pri)
        }
        @event.ext_log if $opt['e'] && @ash.stat['ver']
        @interval=@event.interval
        @tid_auto=auto_update
        @post_exe_procs << proc{
          @site_stat['auto'] = @tid_auto && @tid_auto.alive?
        }
        @ash.stat.post_upd_procs << proc{
          @event.upd.exec
        }
      end

      def auto_update
        ThreadLoop.new("Watch:Auto(#@id)",14){
          if @event.get('exec').empty?
            verbose("Auto","Update(#{@ash.stat['time']})")
            begin
              @event.queue('auto',3,[['upd']]).upd.exec
            rescue InvalidID
              errmsg
            rescue
              warn $!
            end
          end
          @event.next_upd
          verbose("Auto","Update Sleep(#{@event.period}sec)")
          sleep @event.period
        }
      end
    end

    class Command < Command
      attr_reader :rem,:ash
      def add_rem(ash)
        unshift @rem=ash.cobj.rem
      end
    end
        
    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('celts')
      cfg=Config.new('test',{:site_stat => Prompt.new})
      begin
        Frm::List.new(cfg)
        App::List.new(cfg)
        Wat.new(ARGV.shift,cfg).ext_shell.shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
