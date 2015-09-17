#!/usr/bin/ruby
require "libappexe"
require "libwatview"

module CIAX
  module Wat
    # cfg should have [:sub_list]
    class Exe < Exe
      attr_reader :sub,:stat
      def initialize(id,cfg)
        super(id,cfg)
        @sub=@cfg[:sub_list].get(@id)
        @cobj.add_rem(@sub.cobj.rem)
        @stat=Event.new.ext_rsp(@sub.stat)
        @site_stat=@sub.site_stat.add_db('auto'=>'@','watch'=>'&')
        @sub.batch_interrupt=@stat.get('int')
        @sub_proc=proc{verbose("Dummy exec")}
        opt_mode
      end

      def ext_shell
        super
        @cfg[:output]=View.new(@stat)
        @cobj.loc.add_view
        input_conv_set
        self
      end

      private
      def ext_test
        @stat.post_upd_procs << proc{|ev|
          verbose("Propagate Event#upd -> upd")
          @site_stat.put('watch',ev.active?)
          block=ev.get('block').map{|id,par| par ? nil : id}.compact
          @cobj.rem.ext.valid_sub(block)
        }
        @sub.pre_exe_procs << proc{|args| @stat.block?(args) }
        @stat.ext_file
        super
      end

      def ext_driver
        ext_test
        @stat.ext_log if $opt['e'] && @sub.stat['ver']
        @stat.post_upd_procs << proc{|ev|
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

      def auto_update
        @stat.next_upd
        ThreadLoop.new("Watch:Auto(#@id)",14){
          if @stat.get('exec').empty?
            verbose("Auto Update(#{@sub.stat['time']})")
            begin
              @stat.queue('auto',3,[['upd']])
            rescue InvalidID
              errmsg
            rescue
              warning $!
            end
          end
          @stat.next_upd
          verbose("Auto Update Sleep(#{@stat.period}sec)")
          sleep @stat.period
        }
      end
    end

    class List < Site::List
      def initialize(cfg,attr={})
        super(cfg,App::List.new(cfg))
        set_dbi(@sub_list.cfg[:db])
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
