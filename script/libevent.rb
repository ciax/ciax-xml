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
        @periodm = 300_000
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
      def update?
        dif = (self[:upd_next].to_i - now_msec)
        return false if dif.between?(0, @periodm)
        self[:upd_next] = now_msec + @periodm
        verbose { "Next Update is #{dif / 1000}sec later" }
        true
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
