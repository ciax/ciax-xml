#!/usr/bin/ruby
require 'libstatus'
require 'librerange'

module CIAX
  module Wat
    class Event < DataH
      attr_reader :on_act_procs, :on_deact_procs, :interval
      def initialize
        super('event')
        @interval = 0.1
        @period=300
        @last_updated = 0
        @on_act_procs = [proc { verbose { 'Processing OnActProcs' } }]
        @on_deact_procs = [proc { verbose { 'Processing OnDeActProcs' } }]
        # For Array element
        %w(active exec block int).each { |i| @data[i] ||= Array.new }
        # For Hash element
        %w(crnt last res).each { |i| @data[i] ||= {} }
        # For Time element
        %w(act_start act_end).each { |i| @data[i] ||= now_msec }
        self
      end

      def active?
        ! @data['active'].empty?
      end

      def block?(args)
        cid = args.join(':')
        blkcmd = @data['block'].map { |ary| ary.join(':') }
        verbose(!blkcmd.empty?) { "BLOCKING:#{blkcmd}" }
        blkcmd.any? { |blk| /#{blk}/ === cid } && Msg.cmd_err("Blocking(#{args})")
      end

      def next_upd(slp=nil)
        dif=(@data['upd_next'] || 0) - now_msec
        if dif > 0
          verbose { "Auto Update Sleep(#{@period}sec)" }
          sleep dif if slp
        else
          @data['upd_next'] = now_msec + @period * 1000
        end
        upd
      end

      def ext_rsp(stat, sv_stat = {})
        extend(Rsp).ext_rsp(stat, sv_stat)
      end
    end

    if __FILE__ == $0
      require 'libinsdb'
      OPT.parse('h:')
      event = Event.new
      begin
        dbi = Ins::Db.new.get(ARGV.shift)
        event.set_dbi(dbi)
        if OPT.host
          event.ext_http(OPT.host)
        else
          event.ext_save.ext_load
        end
        puts STDOUT.tty? ? event : event.to_j
      rescue InvalidID
        OPT.usage('(opt) [site]')
      end
    end
  end
end
