#!/usr/bin/env ruby
require 'libprompt'
require 'libappstat'
require 'librerange'
# CIAX-XML
module CIAX
  # Watch Layer
  module Wat
    # Event Data
    class Event < Statx
      attr_reader :wdb, :status, :on_act_procs, :on_deact_procs, :interval
      def initialize(dbi = nil, status = nil)
        super('event', dbi, Ins::Db)
        @wdb = @dbi[:watch]
        @interval = 0.1
        @periodm = 300_000
        @timeout = 10_000
        @last_updated = 0
        self[:format_ver] = 1
        ___init_struct
        ___init_status(status)
      end

      def active?
        !self[:active].empty?
      end

      def block?(args)
        cid = args.join(':')
        blkcmd = self[:block].map { |ary| ary.join(':') }
        verbose { "BLOCKING:#{blkcmd}" } unless blkcmd.empty?
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

      def mark_start
        self[:act_time][0] = mark_end
      end

      def mark_end
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

      def ___init_status(status)
        _init_sub_stat(status, App::Status, @dbi)
        propagation(@sub_stat)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      Opt::Get.new('[site]', options: 'h') do |opt, args|
        puts Event.new(args.shift).cmode(opt.host)
      end
    end
  end
end
