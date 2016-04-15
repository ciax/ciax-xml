#!/usr/bin/ruby
require 'libupd'
require 'libmcrcond'

module CIAX
  module Mcr
    # Element of Record
    class Step < Upd
      def initialize(db, depth, dummy = nil)
        super()
        update db
        self[:depth] = depth
        @dummy = dummy
      end

      # Interactive section
      def exec?
        _set_result('approval', 'dryrun', !@dummy)
      end

      # Execution section
      def async?
        _set_result('forked', 'entering', /true|1/ =~ self[:async])
      end

      def sleeping(s)
        _progress(s)
        _set_result("slept(#{s})")
      end

      def ext_cond(dev_list)
        extend(Condition).ext_cond(dev_list)
      end

      private

      # Not Condition Step
      def _set_result(tmsg, fmsg = nil, tf = true)
        res = tf ? tmsg : fmsg
        self[:result] = res if res
        tf
      ensure
        upd
      end

      def _progress(total, &cond)
        itv = @dummy ? 0 : 1
        total.to_i.times do|n| # gives number or nil(if break)
          self[:count] = n + 1
          break if cond && cond.call
          Kernel.sleep itv
          post_upd
          _show('.')
        end
      end
    end
  end
end
