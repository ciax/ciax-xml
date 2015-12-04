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
        itv = OPT.test? ? 0 : 0.1
        itv *= 10 if OPT[:m]
        _show title
        res = _progress(self[:retry], itv)
        self[:result] = res ? 'timeout' : 'pass'
        upd
        res
      end

      def sleeping(s)
        _show title
        _progress(s)
        self[:result] = "slept(#{s})"
        upd
        false
      end

      def ok?
        _show title
        upd
        'ok'
      end

      def skip?
        _show title
        res = @cond.ok?('skip', 'enter')
        upd
        res
      end

      def fail?
        _show title
        res = !@cond.ok?('pass', 'failed')
        upd
        res
      end

      # Interactive section
      def exec?
        _show title
        res = !dryrun?
        self[:result] = res ? 'exec' : 'skip'
        upd
        res
      end

      # Execution section
      def async?
        _show title
        res = (/true|1/ =~ self[:async])
        self[:result] = res ? 'forked' : 'entering'
        upd
        res
      end

      # Display section
      def to_v
        title + result
      end

      private

      def upd_core
        _show result
        self
      end

      def _show(msg)
        print msg if Msg.fg?
      end

      def dryrun?
        !OPT[:m] && self[:action] = 'dryrun'
      end

      def _progress(total, itv = 1)
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
