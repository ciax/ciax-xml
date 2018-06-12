#!/usr/bin/ruby
require 'libupd'

module CIAX
  module Mcr
    # Element of Record
    class Step < Upd
      attr_reader :opt
      def initialize(db, depth, opt)
        super()
        update db
        self[:depth] = depth
        @opt = opt
        # Prevent time update on step
        @cmt_procs.clear
      end

      #### In Drive mode
      # Interactive section
      def exec?
        select_res('approval', 'dryrun', !@opt.dry?)
      end

      # Execution section
      def async?
        select_res('forked', 'entering', /true|1/ =~ self[:async])
      end

      def sleeping
        s = self[:val] || return
        progress(s)
        self.result = 'slept'
      end

      # Condition section
      def skip?(tf)
        select_res('skip', 'enter', tf)
      end

      def fail?(tf)
        select_res('failed', 'pass', tf)
      end

      # Not Condition Step, returns t/f
      def select_res(tmsg, fmsg, tf)
        self.result = tf ? tmsg : fmsg
        tf
      end

      def result=(msg)
        self[:result] = msg.downcase
      ensure
        cmt
      end

      def progress(total, &cond)
        itv = @opt.log? ? 1 : 0
        total.to_i.times do |n| # gives number or nil(if break)
          self[:count] = n + 1
          break if cond && yield
          Kernel.sleep itv
          dot if Msg.fg?
          cmt
        end
      end
    end
  end
end
