#!/usr/bin/ruby
require 'libenumx'

module CIAX
  # Macro Layer
  module Mcr
    # Check Coindition
    class Condition < Hashx
      def initialize(cond, dev_list, step)
        super()
        @dev_list = type?(dev_list, Wat::List)
        @exes = cond.map { |h| h[:site] }.uniq.map { |s| @dev_list.get(s).sub }
        @condition = cond
        @step = step
      end

      # Sub methods
      def ok?(t = nil, f = nil)
        res = _all_conditions?(_scan)
        @step[:result] = (res ? t : f) if t || f
        res
      end

      private

      def _scan
        @exes.each_with_object({}) do |obj, hash|
          _wait_busy(obj)
          st = hash[obj.id] = obj.stat
          verbose { "Scanning #{obj.id} (#{st[:time]})/(#{st.object_id})" }
        end
      end

      def _wait_busy(obj)
        return if obj.join
        @step[:result] = 'timeout'
        fail Interlock
      end

      def _all_conditions?(stats)
        conds = @condition.map do|h|
          _condition(stats[h[:site]], h)
        end
        @step[:conditions] = conds
        conds.all? { |h| h[:res] }
      end

      def _condition(stat, h)
        c = {}
        %i(site var form cmp cri).each { |k| c[k] = h[k] }
        real = _get_real(stat, c)
        res = method(c[:cmp]).call(c[:cri], real)
        c.update(real: real, res: res)
        verbose { c.map { |k, v| format('%s=%s', k, v) }.join(',') }
        c
      end

      def _get_real(stat, h)
        warning('No form specified') unless h[:form]
        form = (h[:form] || :data).to_sym
        var = h[:var]
        warning("No [#{var}] in Status[#{form}]") unless stat[form].key?(var)
        stat[form][var]
      end

      # Operators
      def equal(a, b)
        a == b
      end

      def not(a, b)
        a != b
      end

      def match(a, b)
        /#{a}/ =~ b
      end

      def unmatch(a, b)
        /#{a}/ !~ b
      end
    end
  end
end
