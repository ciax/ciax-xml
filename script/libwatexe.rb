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
        @stat=Event.new.set_dbi(@dbi)
        @sv_stat=@sub.sv_stat.add_db('auto'=>'@','watch'=>'&')
        @sub.batch_interrupt=@stat.get('int')
        @mode=@sub.mode
        @host=@sub.host
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
        ext_share
      end

      def ext_driver
        ext_share
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
          @sv_stat.put('auto',@tid_auto && @tid_auto.alive?)
        }
        self
      end

      def ext_share
        @stat.post_upd_procs << proc{|ev|
          verbose("Propagate Event#upd -> upd")
          @sv_stat.put('watch',ev.active?)
          block=ev.get('block').map{|id,par| par ? nil : id}.compact
          @cobj.rem.ext.valid_sub(block)
        }
        @sub.pre_exe_procs << proc{|args| @stat.block?(args) }
        @stat.ext_rsp(@sub.stat).ext_file
        self
      end

      def auto_update
        reg=(@stat.dbi[:watch]||{})[:regular]||return
        period=reg['period'].to_i
        @stat.next_upd(period)
        ThreadLoop.new("Watch:Auto(#@id)",14){
          if @stat.get('exec').empty?
            verbose("Auto Update(#{@sub.stat['time']})")
            begin
              @stat.queue('auto',3,reg[:exec])
            rescue InvalidID
              errmsg
            rescue
              warning $!
            end
          end
          @stat.next_upd(period)
          verbose("Auto Update Sleep(#{period}sec)")
          sleep period
        }
      end
    end

    class List < Site::List
      def initialize(cfg,top_list=nil)
        super(cfg,top_list||self,App::List)
        set_db(@sub_list.db)
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('ceh:lts')
      cfg=Config.new
      cfg[:site]=ARGV.shift
      begin
        List.new(cfg).ext_shell.shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
