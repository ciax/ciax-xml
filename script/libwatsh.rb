#!/usr/bin/ruby
require "libwatview"
require "libappsh2"

module CIAX
  module Watch
    # cfg should have [:app_list](App::List)
    def self.new(cfg)
      Msg.type?(cfg,Hash)
      if $opt['s'] or $opt['e']
        ash=Watch::Sv.new(cfg)
        cfg['host']='localhost'
      end
      ash=Watch::Cl.new(cfg) if (cfg['host']=$opt['h']) || $opt['c']
      ash||Watch::Test.new(cfg)
    end

    class Exe < Exe
      def initialize(cfg)
        @adb=type?(cfg[:db],Db)
        @event=Event.new.set_db(@adb)
        super('watch',@event['id'],Command.new(cfg))
        @ash=type?(cfg[:app_list][@id],App::Exe)
        @mode=@ash.mode
        @stat=@ash.stat
        @cobj.svdom.replace @ash.cobj.svdom
        @output=@wview=View.new(@adb,@event).ext_prt
        ext_shell(@output){
          {'auto'=>'@','watch'=>'&','isu'=>'*'}.map{|k,v|
            v if self[k]
          }.join('')
        }
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
        @event.event_procs << proc{|p,args|
          Msg.msg("#{args} is issued by event")
        }
      end
    end

    class Cl < Exe
      def initialize(cfg)
        super
        host=type?(cfg['host']||@adb['host']||'localhost',String)
        @event.ext_http(host)
        @stat.post_upd_procs << proc{@event.upd} # @event is independent from @stat
      end
    end

    class Sv < Exe
      def initialize(cfg)
        super
        @event.ext_rsp(@stat).ext_file
        update({'auto'=>nil,'watch'=>nil,'isu'=>nil})
        @event.event_procs << proc{|p,args|
          verbose("Watch","#@id/Issue(#{p}):#{args}")
          @ash.exe(args,'event',2)
        }
        @event.ext_logging if $opt['e'] && @stat['ver']
        @stat.post_upd_procs << proc{self['watch'] = @event.active?}
        @interval=@event['interval']
        @event.post_upd_procs << proc{|wat|
          block=wat.data['block'].map{|id,par| par ? nil : id}.compact
          @ash.cobj.extgrp.valid_sub(block)
        }
        @ash.pre_exe_procs << proc{|args|
          @event.block?(args)
        }
        tid_auto=auto_update
        @post_exe_procs << proc{
          self['auto'] = tid_auto && tid_auto.alive?
        }
        ext_server(@ash.adb['port'].to_i+2000) if ['e','s'].any?{|i| $opt[i]}
      end

      def auto_update
        Threadx.new("Update Thread(#@layer:#@id)",4){
          int=(@event['period']||300).to_i
          loop{
            sleep int
            begin
              @ash.exe(['upd'],'auto',3)
            rescue InvalidID
              errmsg
            end
            verbose("Watch","Auto Update(#{@stat['time']})")
          }
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
        jumpgrp(Watch.new(@cfg))
      end
    end

    if __FILE__ == $0
      ENV['VER']||='init/'
      GetOpts.new('chset')
      begin
        puts List.new.shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
  end
  end
end
