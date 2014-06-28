#!/usr/bin/ruby
require 'libstatus'
require 'librerange'

module CIAX
  module Watch
    class Data < Datax
      # @ event_procs*
      attr_accessor :event_procs
      def initialize
        @ver_color=6
        super('watch')
        self['period']=300
        self['interval']=0.1
        self['astart']=now_msec
        self['aend']=now_msec
        #For Array element (@data contains only Array)
        ['active','exec','block','int'].each{|i| @data[i]||=Array.new}
        #For Hash element (another data will be stored to self)
        ['crnt','last','res'].each{|i| self[i]||={}}
        @event_procs=[]
        self
      end

      def active?
        ! @data['active'].empty?
      end

      def block?(args)
        cid=args.join(':')
        blkcmd=@data['block'].map{|ary| ary.join(':')}
        verbose("Watch","BLOCKING:#{blkcmd}") unless blkcmd.empty?
        blkcmd.any?{|blk| /#{blk}/ === cid} && Msg.cmd_err("Blocking(#{args})")
      end

      def batch_on_event
        # block parm = [priority(2),args]
        cmdary=@data['exec'].each{|args|
          @event_procs.each{|p| p.call([2,args])}
          verbose("Watch","ISSUED_AUTO:#{args}")
        }.dup
        @data['exec'].clear
        cmdary
      end

      def batch_on_interrupt
        verbose("Watch","Interrupt:#{@data['int']}")
        batch=@data['int'].dup
        @data['int'].clear
        batch
      end

      def ext_upd(stat)
        extend(Upd).ext_upd(stat)
      end
    end
  end

  if __FILE__ == $0
    require "libsitedb"
    GetOpts.new('h:')
    watch=Watch::Data.new
    begin
      adb=Site::Db.new.set(ARGV.shift)[:adb]
      watch.skeleton(adb)
      if host=$opt['h']
        watch.ext_http(host)
      else
        watch.ext_file
      end
      puts STDOUT.tty? ? watch : watch.to_j
    rescue InvalidID
      $opt.usage("(opt) [id]")
    end
  end
end
