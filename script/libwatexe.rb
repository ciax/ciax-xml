#!/usr/bin/ruby
require "libsitelist"
require "libwatview"
require "libappexe"

module CIAX
  $layers['wat']=Wat
  module Wat
    def self.new(site_cfg,layer_cfg={})
      Msg.type?(site_cfg,Hash)
      if $opt.delete('l')
        layer_cfg['host']='localhost'
        Sv.new(site_cfg,layer_cfg)
      elsif host=$opt['h']
        layer_cfg['host']=host
      elsif $opt['c']
      elsif $opt['s'] or $opt['e']
        return Sv.new(site_cfg,layer_cfg)
      else
        return Test.new(site_cfg,layer_cfg)
      end
      Cl.new(site_cfg,layer_cfg)
    end

    # site_cfg should have 'id',:site_db,:site_list,:site_stat
    class Exe < Exe
      attr_reader :ash
      def initialize(site_cfg,layer_cfg={})
        @cls_color=3
        super
        @site_stat.add_db('auto'=>'@','watch'=>'&')
        @ash=@cfg[:site_list].get("app:#{@id}")
        @event=Event.new.set_db(@ash.adb)
        @wview=View.new(@ash.adb,@event)
        @ash.batch_interrupt=@event.get('int')
        @cobj.svdom.replace @ash.cobj.svdom
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
        @ash.cobj.ext_sub(block)
        verbose("Watch","Propagate Event#upd -> Watch::Exe#upd")
        self
      end

      def ext_shell
        super
        vg=@cobj.lodom.add_group('caption'=>"Change View Mode",'color' => 9)
        vg.add_item('vis',"Visual mode").set_proc{@output=@wview;''}
        vg.add_item('raw',"Raw Print mode").set_proc{@output=@event;''}
        self
      end
    end

    class Test < Exe
      def initialize(site_cfg,layer_cfg={})
        super
        init_sv
        # @event is independent from @ash.stat
        @ash.stat.post_upd_procs << proc{@event.upd}
      end
    end

    class Cl < Exe
      def initialize(site_cfg,layer_cfg={})
        super
        @event.ext_http(@ash.host)
        # @event is independent from @ash.stat
        @pre_exe_procs << proc{@event.upd}
      end
    end

    class Sv < Exe
      def initialize(site_cfg,layer_cfg={})
        super
        init_sv
        @event.ext_file
        @event.def_proc=proc{|args,src,pri|
            @ash.exe(args,src,pri)
        }
        @ash.stat.post_upd_procs << proc{
          @event.upd.exec('event',2)
        }
        @event.ext_log if $opt['e'] && @ash.stat['ver']
        @interval=@event.interval
        tid_auto=auto_update
        @post_exe_procs << proc{
          @site_stat['auto'] = tid_auto && tid_auto.alive?
        }
      end

      def auto_update
        ThreadLoop.new("Watch:Auto(#@id)",14){
          begin
            @event.exec('auto',3,[['upd']])
          rescue InvalidID
            errmsg
          end
          verbose("Watch","Auto Update(#{@ash.stat['time']})")
          @event.next_upd
          sleep @event.period
        }
      end
    end

    class List < Site::List
      def initialize
        super('wat')
      end
    end

    if __FILE__ == $0
      require "libsh"
      ENV['VER']||='initialize'
      GetOpts.new('celts')
      id=ARGV.shift
      begin
        List.new.ext_shell.shell(id)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
