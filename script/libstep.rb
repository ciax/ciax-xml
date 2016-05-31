#!/usr/bin/ruby
require 'libupd'

module CIAX
  module Mcr
    # Element of Record
    class Step < Upd
      attr_reader :dummy
      def initialize(db, depth, dummy = nil)
        super()
        update db
        self[:depth] = depth
        @dummy = dummy
      end

      #### In Drive mode
      # Interactive section
      def exec?
        set_result('approval', 'dryrun', !@dummy)
      end

      # Execution section
      def async?
        set_result('forked', 'entering', /true|1/ =~ self[:async])
      end

      def sleeping
        s = self[:val] || return
        progress(s)
        set_result('slept')
      end

      # Condition section
      def skip?(tf)
        set_result('skip', 'enter', tf)
      end

      def fail?(tf)
        set_result('failed', 'pass', tf)
      end

      # Not Condition Step
      def set_result(tmsg, fmsg = nil, tf = true)
        res = tf ? tmsg : fmsg
        self[:result] = res if res
        tf
      ensure
        cmt
      end

      def progress(total, &cond)
        itv = @dummy ? 0 : 1
        total.to_i.times do|n| # gives number or nil(if break)
          self[:count] = n + 1
          break if cond && cond.call
          Kernel.sleep itv
          print '.' if Msg.fg?
          cmt
        end
      end
    end
  end
end
