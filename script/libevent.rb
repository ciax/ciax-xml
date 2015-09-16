#!/usr/bin/ruby
require 'libstatus'
require 'librerange'

module CIAX
  module Wat
    class Event < DataH
      attr_reader :period,:interval
      def initialize
        super('event')
        @period=300
        @interval=0.1
        @data['act_start']=now_msec
        @data['act_end']=now_msec
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
        verbose("BLOCKING:#{blkcmd}") unless blkcmd.empty?
        blkcmd.any?{|blk| /#{blk}/ === cid} && Msg.cmd_err("Blocking(#{args})")
      end

      def next_upd
        @data['upd_next']=now_msec+@period*1000
        self
      end

      def ext_rsp(stat)
        extend(Rsp).ext_rsp(stat)
      end
    end

    if __FILE__ == $0
      require "libinsdb"
      GetOpts.new('h:')
      event=Event.new
      begin
        dbi=Ins::Db.new.get(ARGV.shift)
        event.set_db(dbi)
        if host=$opt.host
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
