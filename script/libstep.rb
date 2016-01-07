#!/usr/bin/ruby
require 'libupd'
require 'libmcrprt'
require 'libmcrcond'

module CIAX
  module Mcr
    # Element of Record
    class Step < Upd
      include PrtShare
      def initialize(db, dev_list)
        super()
        update db
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
        @cond.ok?('skip', 'enter') && !OPT.test?
      ensure
        upd
      end

      def fail?
        !@cond.ok?('pass', 'failed')
      ensure
        upd
      end

      # Interactive section
      def exec?
        _set_result('skip', 'approval', dryrun?)
      end

      # Execution section
      def async?
        _set_result('forked', 'entering', /true|1/ =~ self[:async])
      end

      # Display section
      def to_v
        title + result
      end

      def show_title
        print title if Msg.fg?
        self
      end

      private

      def upd_core
        _show result
        self
      end

      def _show(msg)
        print msg if Msg.fg?
      end

      def _set_result(tmsg, fmsg = nil, tf = true)
        self[:result] = tf ? tmsg : fmsg
        tf
      ensure
        upd
      end

      def dryrun?
        !OPT[:m] && self[:action] = 'dryrun'
      end

      def _progress(total)
        itv = OPT.test? ? 0 : 0.1
        itv *= 10 if OPT[:m]
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
