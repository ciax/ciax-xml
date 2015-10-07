#!/usr/bin/ruby
require 'libstatus'
require 'librerange'
# CIAX-XML
module CIAX
  # Watch Layer
  module Wat
    # Event Data
    class Event < DataH
      attr_reader :on_act_procs, :on_deact_procs, :interval
      def initialize
        super('event')
        @interval = 0.1
        @period = 300
        @last_updated = 0
        @on_act_procs = [proc { verbose { 'Processing OnActProcs' } }]
        @on_deact_procs = [proc { verbose { 'Processing OnDeActProcs' } }]
        # For Array element
        %w(active exec block int).each { |i| @data[i] ||= [] }
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
        return unless blkcmd.any? { |blk| Regexp.new(blk).match(cid) }
        Msg.cmd_err("Blocking(#{args})")
      end

      # Update the next update time
      # Return rest time unless expired
      def next_upd
        dif = ((@data['upd_next'] || 0) - now_msec) / 1000
        return dif if dif.between?(0, @period)
        @data['upd_next'] = now_msec + @period * 1000
        nil
      end

      def sleep
        dif = next_upd
        if dif
          verbose { "Auto Update Sleep(#{dif}sec)" }
          Kernel.sleep dif
        end
        self
      end

      def ext_rsp(stat, sv_stat = {})
        extend(Rsp).ext_rsp(stat, sv_stat)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      OPT.parse('h:')
      event = Event.new
      begin
        dbi = Ins::Db.new.get(ARGV.shift)
        event.setdbi(dbi)
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
