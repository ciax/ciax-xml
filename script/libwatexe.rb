#!/usr/bin/ruby
require "libwatview"
require "libappexe"

module CIAX
  module Wat
    # cfg should have [:app_list](App::List)
    def self.new(cfg)
      Msg.type?(cfg,Hash)
      if $opt['s'] or $opt['e']
        ash=Sv.new(cfg)
        cfg['host']='localhost'
      end
      ash=Cl.new(cfg) if (cfg['host']=$opt['h']) || $opt['c']
      ash||Test.new(cfg)
    end

    class Exe < Exe
      attr_reader :adb,:stat
      def initialize(cfg)
        @adb=type?(cfg[:db],Db)
        @event=Event.new.set_db(@adb)
        super('watch',@event['id'],Command.new(cfg))
        @cls_color=3
        @ash=type?(cfg[:app_list].get(@id),App::Exe)
        @site_stat=@ash.site_stat.add_db('auto'=>'@','watch'=>'&')
        @mode=@ash.mode
        @stat=@ash.stat
        @cobj.svdom.replace @ash.cobj.svdom
        @ash.batch_interrupt=@event.get('int')
        @wview=View.new(@adb,@event).ext_prt
        @output=$opt['j']?@event:@wview
        @event.post_upd_procs << proc{|wat|
          @site_stat['watch'] = @event.active?
          block=wat.get('block').map{|id,par| par ? nil : id}.compact
          @ash.cobj.extgrp.valid_sub(block)
        }
        @ash.pre_exe_procs << proc{|args| @event.block?(args) }
        @prompt_proc=proc{ @site_stat.to_s }
        ext_shell
        # Init View
        vg=@cobj.lodom.add_group('caption'=>"Change View Mode",'color' => 9)
        vg.add_item('prt',"Print mode").set_proc{@output=@wview;''}
        vg.add_item('raw',"Raw Watch mode").set_proc{@output=@event;''}
      end
    end

    class Test < Exe
      def initialize(cfg)
        super
        @event.ext_rsp(@stat)
        @stat.post_upd_procs << proc{@event.upd} # @event is independent from @stat
      end
    end

    class Cl < Exe
      def initialize(cfg)
        super
        host=type?(cfg['host']||@adb['host']||'localhost',String)
        @event.ext_http(host)
        @pre_exe_procs << proc{@event.upd} # @event is independent from @stat
      end
    end

    class Sv < Exe
      def initialize(cfg)
        super
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
          verbose("Watch","Auto Update(#{@stat['time']})")
          @event.next_upd
          sleep @event.period
        }
      end
    end

    class List < Site::List
      def initialize(upper=nil)
        super
        @cfg[:level]='watch'
        @cfg[:app_list]||=App::List.new
        @cfg[:wat_list]=self
      end

      def add(id)
        @cfg[:db]=@cfg[:ldb].set(id)[:adb]
        set(id,Wat.new(@cfg))
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('chset')
      begin
        puts List.new.shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
