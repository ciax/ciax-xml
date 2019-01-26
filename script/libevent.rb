#!/usr/bin/ruby
require 'libprompt'
require 'libstatus'
require 'librerange'
# CIAX-XML
module CIAX
  # Watch Layer
  module Wat
    # Event Data
    class Event < Statx
      attr_reader :on_act_procs, :on_deact_procs, :interval
      def initialize(dbi = nil)
        super('event', dbi, Ins::Db)
        @interval = 0.1
        @periodm = 300_000
        @timeout = 10_000
        @last_updated = 0
        self[:format_ver] = 1
        ___init_struct
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
        cmt
        true
      end

      def updating?
        return true unless active? && now_msec > self[:time] + @timeout
        com_err("stale data over #{(@timeout / 1000).to_i} sec")
      end

      def act_start
        self[:act_time][0] = act_upd
      end

      def act_upd
        self[:act_time][1] = now_msec
      end

      private

      def ___init_struct
        # For Array element
        %i(active exec block int).each { |i| self[i] = [] }
        # For Hash element
        %i(history res).each { |i| self[i] = {} }
        # For Time element
        self[:act_time] = [now_msec, now_msec]
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      GetOpts.new('[site]', options: 'h') do |opt, args|
        event = Event.new(args.shift)
        if opt.host
          event.ext_remote(opt.host)
        else
          event.ext_local_file.ext_load
        end
        puts event
      end
    end
  end
end
