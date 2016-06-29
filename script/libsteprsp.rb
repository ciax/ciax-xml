#!/usr/bin/ruby
require 'libstep'

module CIAX
  # Macro Layer
  module Mcr
    # Check Coindition
    class StepRsp < Step
      def initialize(dev_list, db, depth, dummy = nil)
        super(db, depth, dummy)
        @dev_list = type?(dev_list, Wat::List)
        # App::Exe list used in this Step
        @condition = delete(:cond) || return
        sites = @condition.map { |h| h[:site] }.uniq
        @exes = sites.map { |s| @dev_list.get(s).sub }
      end

      # Conditional judgment section
      def skip?
        wait_dev_ready
        super(_all_conds?)
      end

      def fail?
        wait_dev_ready
        super(!_all_conds?)
      end

      def timeout?
        res = progress(self[:retry]) { active? } ||
              progress(self[:retry].to_i - self[:count]) { _all_conds? }
        set_result('timeout', 'pass', res)
      end

      # obj.waitbusy -> looking at Prompt[:busy]
      # obj.stat -> looking at Status

      def active?
        if @exes.all?(&:active?)
          delete(:busy)
          true
        else
          self[:busy] = true
          false
        end
      end

      # Blocking during busy. (for interlock check)
      def wait_dev_ready
        @exes.each do |obj|
          next if obj.wait_ready
          set_result('timeout')
          raise Interlock
        end
        self
      end

      private

      def _all_conds?
        stats = _scan
        conds = @condition.map do |h|
          _condition(stats[h[:site]], h)
        end
        self[:conditions] = conds
        conds.all? { |h| h[:res] }
      end

      def _scan
        @exes.each_with_object({}) do |obj, hash|
          st = hash[obj.id] = obj.stat.latest
          verbose { "Scanning #{obj.id} (#{st[:time]})/(#{st.object_id})" }
        end
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
        /#{a}/ =~ b ? true : false
      end

      def unmatch(a, b)
        /#{a}/ !~ b ? true : false
      end
    end
  end
end
