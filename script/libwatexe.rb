#!/usr/bin/ruby
require "libwatview"
require "libappexe"

module CIAX
  module Wat
    # cfg should have [:app_list](App::List)
    def self.new(cfg)
      Msg.type?(cfg,Hash)
      if $opt['l']
        $opt.delete('l')
        cfg['host']='localhost'
        Sv.new(cfg)
        Cl.new(cfg)
      elsif (cfg['host']=$opt['h']) or $opt['c']
        Cl.new(cfg)
      elsif $opt['s'] or $opt['e']
        Sv.new(cfg)
      else
        Test.new(cfg)
      end
    end

    class Exe < Exe
      attr_reader :adb,:stat
      def initialize(cfg)
        @adb=type?(cfg[:db],Db)
        @event=Event.new.set_db(@adb)
        @cls_color=3
        super('watch',@event['id'],App::Command.new(cfg))
        @ash=type?(cfg[:app_list].get(@id),App::Exe)
        @wview=View.new(@adb,@event).ext_prt
        @output=$opt['j']?@event:@wview
        @prompt_proc=proc{ @site_stat.to_s }
        ext_shell
        init_view
      end

      def init_sv(cfg)
        @mode=@ash.mode
        @site_stat=@ash.site_stat.add_db('auto'=>'@','watch'=>'&')
        @stat=@ash.stat
        @ash.batch_interrupt=@event.get('int')
        @event.post_upd_procs << proc{|wat|
          @site_stat['watch'] = @event.active?
          block=wat.get('block').map{|id,par| par ? nil : id}.compact
          @ash.cobj.extgrp.valid_sub(block)
        }
        @ash.pre_exe_procs << proc{|args| @event.block?(args) }
      end

      def init_view
        vg=@cobj.lodom.add_group('caption'=>"Change View Mode",'color' => 9)
        vg.add_item('vis',"Visual mode").set_proc{@output=@wview;''}
        vg.add_item('raw',"Raw Print mode").set_proc{@output=@event;''}
      end
    end

    class Test < Exe
      def initialize(cfg)
        super
        @cobj.svdom.replace @ash.cobj.svdom
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
        ext_client(host,@adb['port'].to_i+1000)
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
        ext_server(@adb['port'].to_i+1000)
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
      GetOpts.new('chlset')
      begin
        puts List.new.shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
