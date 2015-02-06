#!/usr/bin/ruby
require "libwatview"
require "libappexe"

module CIAX
  module Wat
    # site_cfg should have [:app_list](App::List)
    def self.new(site_cfg)
      Msg.type?(site_cfg,Hash)
      if $opt.delete('l')
        site_cfg['host']='localhost'
        Sv.new(site_cfg)
      elsif host=$opt['h']
        site_cfg['host']=host
      elsif $opt['c']
      elsif $opt['s'] or $opt['e']
        return Sv.new(site_cfg)
      else
        return Test.new(site_cfg)
      end
      Cl.new(site_cfg)
    end

    class Exe < Exe
      attr_reader :adb,:stat,:ash
      def initialize(site_cfg)
        @cls_color=3
        super
        @cfg[:site_stat].add_db('auto'=>'@','watch'=>'&')
        @adb=@cfg[:db]=type?(site_cfg[:adb],Db)
        @event=Event.new.set_db(@adb)
        @cfg[:batch_interrupt]=@event.get('int')
        @ash=App.new(@cfg)
        @cobj=Command.new(@cfg).add_nil
        @wview=View.new(@adb,@event)
        @cobj.svdom.replace @ash.cobj.svdom
        @output=$opt['j']?@event:@wview
        ext_shell
      end

      def init_sv
        @mode=@ash.mode
        @stat=@ash.stat
        @event.post_upd_procs << proc{upd}
        @stat.post_upd_procs << proc{
          verbose("Watch","Propagate Status#upd -> Event#upd")
        }
        @ash.pre_exe_procs << proc{|args| @event.block?(args) }
      end

      def upd
        @cfg[:site_stat]['watch'] = @event.active?
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
      def initialize(site_cfg)
        super
        init_sv
        @event.ext_rsp(@stat)
        # @event is independent from @stat
        @stat.post_upd_procs << proc{
          @event.upd
        }
      end
    end

    class Cl < Exe
      def initialize(site_cfg)
        super
        host=type?(@cfg['host']||@adb['host']||'localhost',String)
        @event.ext_http(host)
        @pre_exe_procs << proc{@event.upd} # @event is independent from @stat
      end
    end

    class Sv < Exe
      def initialize(site_cfg)
        super
        init_sv
        @event.ext_rsp(@stat).ext_file
        @event.def_proc=proc{|args,src,pri|
            @ash.exe(args,src,pri)
        }
        @stat.post_upd_procs << proc{
          @event.upd.exec('event',2)
        }
        @event.ext_log if $opt['e'] && @stat['ver']
        @interval=@event.interval
        tid_auto=auto_update
        @post_exe_procs << proc{
          @cfg[:site_stat]['auto'] = tid_auto && tid_auto.alive?
        }
      end

      def auto_update
        ThreadLoop.new("Watch:Auto(#@id)",14){
          begin
            @event.exec('auto',3,[['upd']])
          rescue InvalidID
            errmsg
          end
          verbose("Watch","Auto Update(#{@stat['time']})")
          @event.next_upd
          sleep @event.period
        }
      end
    end

    if __FILE__ == $0
      require "libsitedb"
      ENV['VER']||='initialize'
      GetOpts.new('celst')
      id=ARGV.shift
      begin
        cfg=Site::Db.new.set(id)
        puts Wat.new(cfg).shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
