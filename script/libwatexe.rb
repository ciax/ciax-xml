#!/usr/bin/ruby
require "libwatview"
require "libappexe"

module CIAX
  module Wat
    # cfg should have [:app_list](App::List)
    def self.new(cfg)
      Msg.type?(cfg,Hash)
      if $opt.delete('l')
        cfg['host']='localhost'
        Sv.new(cfg)
      elsif host=$opt['h']
        cfg['host']=host
      elsif $opt['c']
      elsif $opt['s'] or $opt['e']
        return Sv.new(cfg)
      else
        return Test.new(cfg)
      end
      Cl.new(cfg)
    end

    class Jump < LongJump; end

    class Exe < Exe
      attr_reader :adb,:stat
      def initialize(cfg)
        @adb=type?(cfg[:db],Db)
        @event=Event.new.set_db(@adb)
        @cls_color=3
        super('wat',@event['id'])
        @ash=type?(cfg.layers[:app].get(@id),App::Exe)
        @cobj.svdom.replace @ash.cobj.svdom
        @site_stat=@ash.site_stat.add_db('auto'=>'@','watch'=>'&')
        @wview=View.new(@adb,@event)
        @output=$opt['j']?@event:@wview
        ext_shell
      end

      def init_sv(cfg)
        @mode=@ash.mode
        @stat=@ash.stat
        @ash.batch_interrupt=@event.get('int')
        @event.post_upd_procs << proc{|wat|
          @site_stat['watch'] = @event.active?
          block=wat.get('block').map{|id,par| par ? nil : id}.compact
          @ash.cobj.extgrp.valid_sub(block)
        }
        @ash.pre_exe_procs << proc{|args| @event.block?(args) }
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
      def initialize(cfg)
        super
        init_sv(cfg)
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
        ext_client(host,@adb['port'].to_i+100)
      end
    end

    class Sv < Exe
      def initialize(cfg)
        super
        init_sv(cfg)
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
        ext_server(@adb['port'].to_i+100)
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
        super(Wat,upper)
        @cfg.layers[:wat]=self
        App::List.new(@cfg)
      end

      def add(id)
        @cfg[:db]=@cfg[:ldb].set(id)[:adb]
        set(id,Wat.new(@cfg))
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('chlset')
      begin
        puts List.new.shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
