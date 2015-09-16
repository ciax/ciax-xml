#!/usr/bin/ruby
require "libappexe"
require "libwatview"

module CIAX
  module Wat
    # cfg should have [:sub_list]
    class Exe < Exe
      attr_reader :sub,:stat
      def initialize(id,cfg,attr={})
        super
        @sub=@cfg[:sub_list].get(@id)
        @stat=@sub.stat
        @host=@sub.host
        @cobj.add_rem(@sub.cobj.rem)
        @event=Event.new.ext_rsp(@sub.stat)
        @site_stat=@sub.site_stat.add_db('auto'=>'@','watch'=>'&')
        @sub.batch_interrupt=@event.get('int')
        @sub_proc=proc{verbose("Dummy exec")}

        opt_mode
      end

      def ext_shell
        super
        @cfg[:output]=View.new(@event)
        @cobj.loc.add_view
        input_conv_set
        self
      end

      private
      def ext_test
        @event.post_upd_procs << proc{|ev|
          verbose("Propagate Event#upd -> upd")
          @site_stat.put('watch',ev.active?)
          block=ev.get('block').map{|id,par| par ? nil : id}.compact
          @cobj.rem.ext.valid_sub(block)
        }
        @sub.pre_exe_procs << proc{|args| @event.block?(args) }
        @event.ext_file
        super
      end

      def ext_driver
        ext_test
        @event.ext_log if $opt['e'] && @sub.stat['ver']
        @event.post_upd_procs << proc{|ev|
          ev.get('exec').each{|src,pri,args|
            verbose("Executing:#{args} from [#{src}] by [#{pri}]")
            @sub.exe(args,src,pri)
          }.clear
          sleep ev.interval
        }
        @tid_auto=auto_update
        @post_exe_procs << proc{
          @site_stat.put('auto',@tid_auto && @tid_auto.alive?)
        }
        super
      end

      def ext_client
        @event.ext_http(@host)
        # @event is independent from @sub.stat
        @pre_exe_procs << proc{@event.upd}
        super
      end

      def auto_update
        @event.next_upd
        ThreadLoop.new("Watch:Auto(#@id)",14){
          if @event.get('exec').empty?
            verbose("Auto Update(#{@sub.stat['time']})")
            begin
              @event.queue('auto',3,[['upd']])
            rescue InvalidID
              errmsg
            rescue
              warn $!
            end
          end
          @event.next_upd
          verbose("Auto Update Sleep(#{@event.period}sec)")
          sleep @event.period
        }
      end
    end

    class List < Site::List
      def initialize(cfg,attr={})
        attr[:sub_list]=App::List.new(cfg)
        super
        set_db(@sub_list.cfg[:db])
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('ceh:lts')
      cfg=Config.new
      cfg[:site]=ARGV.shift
      cfg[:jump_groups]=[]
      begin
        List.new(cfg).ext_shell.shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
