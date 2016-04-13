#!/usr/bin/ruby
require 'libenumx'

module CIAX
  # Macro Layer
  module Mcr
    # Check Coindition
    module Condition
      def self.extended(obj)
        Msg.type?(obj, Step)
      end

      def ext_cond(dev_list)
        @dev_list = type?(dev_list, Wat::List)
        # App::Exe list used in this Step
        @condition = delete(:cond)
        sites = @condition.map { |h| h[:site] }.uniq
        @exes = sites.map { |s| @dev_list.get(s).sub }
        self
      end

      # Conditional judgment section
      def timeout?
        _set_result('timeout', 'pass', _progress(self[:retry]))
      end

      def skip?
        waiting.ok?('skip', 'enter')
      ensure
        upd
      end

      def fail?
        !waiting.ok?('pass', 'failed')
      ensure
        upd
      end

      # obj.waiting -> looking at Prompt[:busy]
      # obj.stat -> looking at Status

      def ok?(t = nil, f = nil)
        res = _all_conditions?(_scan)
        self[:result] = (res ? t : f) if t || f
        res
      end

      def busy?
        @exes.map(&:busy?).any?
      end

      # Blocking during busy. (for interlock check)
      def waiting
        @exes.each do |obj|
          next if obj.waiting
          self[:result] = 'timeout'
          fail Interlock
        end
        self
      end

      private

      def _scan
        @exes.each_with_object({}) do |obj, hash|
          st = hash[obj.id] = obj.stat
          verbose { "Scanning #{obj.id} (#{st[:time]})/(#{st.object_id})" }
        end
      end

      def _all_conditions?(stats)
        conds = @condition.map do|h|
          _condition(stats[h[:site]], h)
        end
        self[:conditions] = conds
        conds.all? { |h| h[:res] }
      end

      def _condition(stat, h)
        c = {}
        %i(site var form cmp cri).each { |k| c[k] = h[k] }
        real = _get_real(stat, c)
        res = method(c[:cmp]).call(c[:cri], real)
warn res
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

      def _progress(total)
        super { !busy? && _all_conditions?(_scan) }
      end

      # Operators
      def equal(a, b)
        a == b
      end

      def not(a, b)
        a != b
      end

      def match(a, b)
        /#{a}/ =~ b ? true : false
      end

      def unmatch(a, b)
        /#{a}/ !~ b ? true : false
      end
    end
  end
end
