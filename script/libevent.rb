#!/usr/bin/ruby
require 'libstatus'
require 'librerange'

module CIAX
  module Watch
    class Event < Datax
      def initialize
        super('event')
        @cls_color=3
        @pfx_color=12
        self['period']=300
        self['interval']=0.1
        @data['unext']=now_msec
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

      def next_upd
        @data['unext']=now_msec+self['period']
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
