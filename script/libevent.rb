#!/usr/bin/ruby
require 'libstatus'
require 'librerange'

module CIAX
  module Watch
    class Event < Datax
      # @ event_procs*
      attr_accessor :event_procs
      def initialize
        @ver_color=6
        super('event')
        self['period']=300
        self['interval']=0.1
        @data['astart']=now_msec
        @data['aend']=now_msec
        #For Array element
        ['active','exec','block','int'].each{|i| @data[i]||=Array.new}
        #For Hash element
        ['crnt','last','res'].each{|i| @data[i]||={}}
        self
      end

      def active?
        ! @data['active'].empty?
      end

      def block?(args)
        cid=args.join(':')
        blkcmd=@data['block'].map{|ary| ary.join(':')}
        verbose("Event","BLOCKING:#{blkcmd}") unless blkcmd.empty?
        blkcmd.any?{|blk| /#{blk}/ === cid} && Msg.cmd_err("Blocking(#{args})")
      end

      def flush_event
        ary=@data['exec']
        ary.shift ary.size
      end

      def flush_int
        ary=@data['int']
        ary.shift ary.size
      end

      # deprecated
      def batch_on_event
        # block parm = [priority(2),args]
        cmdary=@data['exec'].each{|args|
#          @event_procs.each{|p| p.call([2,args])}
#          verbose("Event","ISSUED_AUTO:#{args}")
        }.dup
        @data['exec'].clear
        cmdary
      end

      def batch_on_interrupt
        verbose("Event","Interrupt:#{@data['int']}")
        batch=@data['int'].dup
        @data['int'].clear
        batch
      end

      def ext_rsp(stat)
        extend(Rsp).ext_rsp(stat)
      end
    end

    if __FILE__ == $0
      require "libsitedb"
      GetOpts.new('h:')
      event=Event.new
      begin
        adb=Site::Db.new.set(ARGV.shift)[:adb]
        event.set_db(adb)
        if host=$opt['h']
        event.ext_http(host)
        else
          event.ext_file
        end
      puts STDOUT.tty? ? event : event.to_j
      rescue InvalidID
        $opt.usage("(opt) [site]")
      end
    end
  end
end
