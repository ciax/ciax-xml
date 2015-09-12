#!/usr/bin/ruby
require "libappexe"
require "libwatview"

module CIAX
  module Wat
    def self.new(id,cfg,attr={})
      if $opt.sv?
        sv=Sv.new(id,cfg,attr)
      elsif $opt.cl?
        Cl.new(id,cfg,attr.update($opt.host))
      else
        Test.new(id,cfg,attr)
      end
    end

    # cfg should have [:sub_list]
    class Exe < Exe
      attr_reader :sub,:stat
      def initialize(id,cfg,attr={})
        super
        @sub=@cfg[:sub_list].get(@id)
        @stat=@sub.stat
        @cobj=Index.new(@cfg)
        @cobj.add_rem(@sub)
        @event=Event.new.set_db(@sub.adb)
        @site_stat=@sub.site_stat.add_db('auto'=>'@','watch'=>'&')
        @sub.batch_interrupt=@event.get('int')
        @sub_proc=proc{verbose("Dummy exec")}
      end

      def ext_sv
        @mode=@sub.mode
        @event.post_upd_procs << proc{|ev|
          verbose("Propagate Event#upd -> upd")
          @site_stat.put('watch',ev.active?)
          block=ev.get('block').map{|id,par| par ? nil : id}.compact
          @cobj.rem.ext.valid_sub(block)
        }
        @sub.pre_exe_procs << proc{|args| @event.block?(args) }
        @event.ext_rsp(@sub.stat).ext_file
        self
      end

      def ext_shell
        super
        @cfg[:output]=View.new(@sub.adb,@event)
        @cobj.loc.add_view
        input_conv_set
        self
      end
    end

    class Test < Exe
      def initialize(id,cfg,attr={})
        super
        ext_sv
      end
    end

    class Cl < Exe
      def initialize(id,cfg,attr={})
        super
        @event.ext_http(@sub.cfg['host'])
        # @event is independent from @sub.stat
        @pre_exe_procs << proc{@event.upd}
      end
    end

    class Sv < Exe
      def initialize(id,cfg,attr={})
        super
        ext_sv
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

    class Index < Local::Index
      attr_reader :rem
      def add_rem(ash)
        unshift @rem=ash.cobj.rem
      end
    end

    class List < Site::List
      def initialize(cfg,attr={})
        attr[:sub_list]=App::List.new(cfg)
        super
        set_db(Ins::Db.new) unless @cfg[:db]
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
