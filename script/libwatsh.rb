#!/usr/bin/ruby
# Ascii Pack
require "libmsg"
require "libwatview"
require "libappsh"

module CIAX
  module Watch
    # cfg should have [:app_list](App::List)
    def self.new(cfg)
      Watch::Sv.new(cfg)
    end

    class Sv < Exe
      def initialize(ash)
        type?(ash,App::Exe)
        super('watch',ash.id)
        @cobj.svdom.replace ash.cobj.svdom
        @event=Event.new.set_db(ash.adb).ext_file
        @event.post_upd_procs << proc{|wat|
          block=wat.data['block'].map{|id,par| par ? nil : id}.compact
          ash.cobj.extgrp.valid_sub(block)
        }
        ash.pre_exe_procs << proc{|args|
          @event.block?(args)
        }
        @output=@wview=View.new(ash.adb,@event).ext_prt
        init_view
        @post_exe_procs.concat(ash.post_exe_procs)
        ext_server(ash.adb['port'].to_i+2000) if ['e','s'].any?{|i| $opt[i]}
        ext_shell(@output)
      end

      def init_view
        @view_grp=@cobj.lodom.add_group('caption'=>"Change View Mode",'color' => 9)
        @view_grp.add_item('wat',"Watch mode").set_proc{@output=@wview;''}
        @view_grp.add_item('rwa',"Raw Watch mode").set_proc{@output=@event;''}
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
        Watch.new(@cfg[:app_list][id])
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
