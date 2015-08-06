#!/usr/bin/ruby
require "libappexe"
require "libwatview"

module CIAX
  module Wat
    include Command

    def self.new(id,cfg,attr={})
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

    # cfg should have [:sub_list]
    class Exe < Exe
      attr_reader :sub
      def initialize(id,cfg,attr={})
        super
        @sub=@cfg[:sub_list].get(@id)
        @cobj=Index.new(@cfg)
        @cobj.add_rem(@sub)
        @event=Event.new.set_db(@sub.adb)
        @site_stat=@sub.site_stat.add_db('auto'=>'@','watch'=>'&')
        @sub.batch_interrupt=@event.get('int')
      end

      def init_sv
        @mode=@sub.mode
        @event.post_upd_procs << proc{upd}
        @sub.stat.post_upd_procs << proc{
          verbose("Propagate Status#upd -> Event#upd")
        }
        @sub.pre_exe_procs << proc{|args| @event.block?(args) }
        @event.ext_rsp(@sub.stat)
      end

      def upd
        @site_stat['watch'] = @event.active?
        block=@event.get('block').map{|id,par| par ? nil : id}.compact
        @cobj.rem.ext.valid_sub(block)
        verbose("Propagate Event#upd -> Watch::Exe#upd")
        self
      end

      def ext_shell
        super
        @cfg[:output]=View.new(@sub.adb,@event)
        @cobj.loc.add_view
        self
      end
    end

    class Test < Exe
      def initialize(id,cfg,attr={})
        super
        init_sv
        # @event is independent from @sub.stat
        @sub.stat.post_upd_procs << proc{@event.upd}
      end
    end

    class Cl < Exe
      def initialize(id,cfg,attr={})
        super
        @event.ext_http(@sub.host)
        # @event is independent from @sub.stat
        @pre_exe_procs << proc{@event.upd}
      end
    end

    class Sv < Exe
      def initialize(id,cfg,attr={})
        super
        init_sv
        @event.ext_file
        @event.def_proc=proc{|args,src,pri|
          @sub.exe(args,src,pri)
        }
        @event.ext_log if $opt['e'] && @sub.stat['ver']
        @interval=@event.interval
        @tid_auto=auto_update
        @post_exe_procs << proc{
          @site_stat['auto'] = @tid_auto && @tid_auto.alive?
        }
        @sub.stat.post_upd_procs << proc{
          @event.upd.exec
        }
      end

      def auto_update
        ThreadLoop.new("Watch:Auto(#@id)",14){
          if @event.get('exec').empty?
            verbose("Auto Update(#{@sub.stat['time']})")
            begin
              @event.queue('auto',3,[['upd']]).upd.exec
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
      GetOpts.new('celts')
      id=ARGV.shift
      cfg=Config.new
      cfg[:jump_groups]=[]
      begin
        List.new(cfg).ext_shell.shell(id)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
