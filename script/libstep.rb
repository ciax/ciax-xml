#!/usr/bin/ruby
require 'libupd'
require 'libmcrcond'

module CIAX
  module Mcr
    # Element of Record
    class Step < Upd
      def initialize(db, dev_list, dummy = nil)
        super()
        update db
        @dummy = dummy
        # [:stat_proc,:exec_proc,:query]
        @cond = Condition.new(delete(:cond), dev_list, self) if db.key?(:cond)
        @break = nil
      end

      # Conditional judgment section
      def timeout?
        _set_result('timeout', 'pass', _progress(self[:retry]))
      end

      def sleeping(s)
        _progress(s)
        _set_result("slept(#{s})")
      end

      def skip?
        @cond.join.ok?('skip', 'enter')
      ensure
        upd
      end

      def fail?
        !@cond.join.ok?('pass', 'failed')
      ensure
        upd
      end

      # Interactive section
      def exec?
        _set_result('approval', 'dryrun', !@dummy)
      end

      # Execution section
      def async?
        _set_result('forked', 'entering', /true|1/ =~ self[:async])
      end

      private

      def _set_result(tmsg, fmsg = nil, tf = true)
        res = tf ? tmsg : fmsg
        self[:result] = res if res
        tf
      ensure
        upd
      end

      def _progress(total)
        itv = @dummy ? 0 : 1
        total.to_i.times do|n| # gives number or nil(if break)
          self[:count] = n + 1
          break if @cond && @cond.ok?
          Kernel.sleep itv
          _show('.')
        end
      end
    end
  end
end
