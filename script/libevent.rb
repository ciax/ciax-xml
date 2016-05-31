#!/usr/bin/ruby
require 'libprompt'
require 'libstatus'
require 'librerange'
# CIAX-XML
module CIAX
  # Watch Layer
  module Wat
    # Event Data
    class Event < Varx
      attr_reader :on_act_procs, :on_deact_procs, :interval
      def initialize(dbi = nil)
        super('event')
        @interval = 0.1
        @period = 300
        @last_updated = 0
        _setdbi(dbi, Ins::Db)
        _init_procs
        _init_struct
        self
      end

      def active?
        !self[:active].empty?
      end

      def block?(args)
        cid = args.join(':')
        blkcmd = self[:block].map { |ary| ary.join(':') }
        verbose(!blkcmd.empty?) { "BLOCKING:#{blkcmd}" }
        return unless blkcmd.any? { |blk| Regexp.new(blk).match(cid) }
        Msg.cmd_err("Blocking(#{args})")
      end

      # Update the next update time
      # Return rest time unless expired
      def next_upd
        dif = ((self[:upd_next] || 0) - now_msec) / 1000
        return dif if dif.between?(0, @period)
        self[:upd_next] = now_msec + @period * 1000
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

      def ext_local_file
        super.load
      end

      private

      def _init_procs
        @on_act_procs = [proc { verbose { 'Processing OnActProcs' } }]
        @on_deact_procs = [proc { verbose { 'Processing OnDeActProcs' } }]
      end

      def _init_struct
        # For Array element
        %i(active exec block int).each { |i| self[i] = [] }
        # For Hash element
        %i(crnt last res).each { |i| self[i] = {} }
        # For Time element
        self[:act_time] = [now_msec, now_msec]
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      GetOpts.new('[site]', 'h:') do |opt|
        event = Event.new
        if opt.host
          event.ext_http(opt.host)
        else
          event.ext_local_file
        end
        puts event
      end
    end
  end
end
