#!/usr/bin/ruby
require 'libstatus'
require 'librerange'

module CIAX
  module Wat
    class Event < DataH
      attr_reader :on_act_procs,:on_deact_procs,:interval
      def initialize
        super('event')
        @interval=0.1
        @last_updated=0
        @on_act_procs=[proc{verbose{"Processing OnActProcs"}}]
        @on_deact_procs=[proc{verbose{"Processing OnDeActProcs"}}]
        #For Array element
        ['active','exec','block','int'].each{|i| @data[i]||=Array.new}
        #For Hash element
        ['crnt','last','res'].each{|i| @data[i]||={}}
        #For Time element
        ['act_start','act_end'].each{|i| @data[i]||=now_msec}
        self
      end

      def active?
        ! @data['active'].empty?
      end

      def block?(args)
        cid=args.join(':')
        blkcmd=@data['block'].map{|ary| ary.join(':')}
        verbose(!blkcmd.empty?){"BLOCKING:#{blkcmd}"}
        blkcmd.any?{|blk| /#{blk}/ === cid} && Msg.cmd_err("Blocking(#{args})")
      end

      def next_upd(period)
        @data['upd_next']=now_msec+period.to_i*1000
        self
      end

      def ext_rsp(stat,sv_stat={})
        extend(Rsp).ext_rsp(stat,sv_stat)
      end
    end

    if __FILE__ == $0
      require "libinsdb"
      GetOpts.new('h:')
      event=Event.new
      begin
        dbi=Ins::Db.new.get(ARGV.shift)
        event.set_dbi(dbi)
        if $opt.host
         event.ext_http($opt.host)
        else
          event.ext_save.ext_load
        end
      puts STDOUT.tty? ? event : event.to_j
      rescue InvalidID
        $opt.usage("(opt) [site]")
      end
    end
  end
end
