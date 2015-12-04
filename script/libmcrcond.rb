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
        @condition = cond
        @step = step
      end

      # Sub methods
      def ok?(t = nil, f = nil)
        stats = _scan
        conds = @condition.map do|h|
          stat = stats[h[:site]]
          _condition(stat, h)
        end
        res = conds.all? { |h| h[:res] }
        @step[:conditions] = conds
        @step[:result] = (res ? t : f) if t || f
        res
      end

      def refresh
        _sites.each do|site|
          verbose { "Refresh Status #{site}" }
          @dev_list.get(site).stat.refresh
        end
      end

      private

      def _scan
        _sites.each_with_object({}) do|site, hash|
          st = hash[site] = @dev_list.get(site).sub.stat.upd
          verbose { "Scanning GetStatus #{site} (#{st[:time]})/(#{st.object_id})" }
        end
      end

      def _sites
        @condition.map { |h| h[:site] }.uniq
      end

      def _condition(stat, h)
        cond = {}
        %i(site var form cmp cri).each { |k| cond[k] = h[k] }
        real = _fetch_form(stat, cond[:form].to_sym, cond[:var])
        res = method(cond[:cmp]).call(cond[:cri], real)
        verbose { "Compare #{cond[:cri].inspect} vs #{real.inspect}(#{cond[:form]})" }
        cond.update(real: real, res: res)
        verbose { cond.map { |k, v| format('%s=%s', k, v) }.join(',') }
        cond
      end

      def _fetch_form(stat, form, var)
        unless form
          warning('No form specified')
          form = :data
        end
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
