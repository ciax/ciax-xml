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
        res = _progress(self[:retry])
        self[:result] = res ? 'timeout' : 'pass'
        upd
        res
      end

      def sleeping(s)
        _progress(s)
        self[:result] = "slept(#{s})"
        upd
        false
      end

      def skip?
        res = @cond.ok?('skip', 'enter')
        upd
        res
      end

      def fail?
        res = !@cond.ok?('pass', 'failed')
        upd
        res
      end

      # Interactive section
      def exec?
        res = !dryrun?
        self[:result] = res ? 'exec' : 'skip'
        upd
        res
      end

      # Execution section
      def async?
        res = (/true|1/ =~ self[:async])
        self[:result] = res ? 'forked' : 'entering'
        upd
        res
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

      def _result(msg)
        self[:result] = msg
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
