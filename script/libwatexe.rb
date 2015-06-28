#!/usr/bin/ruby
require "libappexe"
require "libwatview"

module CIAX
  $layers['w']=Wat
  module Wat
    include Command

    def self.new(id,cfg={},attr={})
      Msg.type?(attr,Hash)
      if $opt.delete('l')
        attr['host']='localhost'
        Sv.new(id,cfg,attr)
      elsif host=$opt['h']
        attr['host']=host
      elsif $opt['c']
      elsif $opt['s'] or $opt['e']
        return Sv.new(id,cfg,attr)
      else
        return Test.new(id,cfg,attr)
      end
      Cl.new(id,cfg,attr)
    end

    # cfg should have [:layers]
    class Exe < Exe
      attr_reader :ash
      def initialize(id,cfg={},attr={})
        super
        @cls_color=3
        @ash=@cfg[:layers].get('app').get(@id)
        @event=Event.new.set_db(@ash.adb)
        @wview=View.new(@ash.adb,@event)
        @site_stat=@ash.site_stat.add_db('auto'=>'@','watch'=>'&')
        @ash.batch_interrupt=@event.get('int')
        @output=$opt['j']?@event:@wview
        @cobj=Index.new(@cfg)
        @cobj.add_rem(@ash)
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
        vg=@cobj.loc.add_view
        vg['vis'].cfg.proc{@output=@wview;''}
        vg['raw'].cfg.proc{@output=@event;''}
        self
      end
    end

    class Test < Exe
      def initialize(id,cfg={},attr={})
        super
        init_sv
        # @event is independent from @ash.stat
        @ash.stat.post_upd_procs << proc{@event.upd}
      end
    end

    class Cl < Exe
      def initialize(id,cfg={},attr={})
        super
        @event.ext_http(@ash.host)
        # @event is independent from @ash.stat
        @pre_exe_procs << proc{@event.upd}
      end
    end

    class Sv < Exe
      def initialize(id,cfg={},attr={})
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

    class Index < GrpAry
      attr_reader :loc,:rem,:ash
      def initialize(cfg,attr={})
        super
        @cfg[:cls_color]=3
        @loc=add(Local::Domain)
      end

      def add_rem(ash)
        unshift @rem=ash.cobj.rem
      end
    end

    class Jump < LongJump; end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('celts')
      cfg=Config.new
      cfg[:jump_groups]=[]
      sl=cfg[:layers]=Site::Layer.new(cfg)
      begin
        sl.add_layer(Frm,Dev)
        sl.add_layer(App,Ins)
        Wat.new(ARGV.shift,cfg).ext_shell.shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
