#!/usr/bin/env ruby
require 'libstatpool'

module CIAX
  # Macro Layer
  module Mcr
    # Element of Record
    class Step
      # Step condition class
      class Condition
        include Msg
        def initialize(cond)
          @conditions = type?(cond, Array)
          sites = @conditions.map { |ref| ref[:site] }.uniq
          @spary = sites.map { |id| type?(yield(id), StatPool) }
        end

        def active?
          @spary.any? { |s| s[:sv_stat].active? }
        end

        # Blocking during busy. (for interlock check)
        def wait_ready
          @spary.each { |s| s[:sv_stat].wait_ready }
          self
        end

        def updating?
          @spary.all? { |s| s[:event].updating? }
        end

        # Get condition result Array with latest stat
        def results
          sdic = ___scan
          @conditions.map do |ref|
            ___condition(sdic[ref[:site]], ref)
          end
        end

        private

        def ___condition(stat, ref)
          c = {}
          %i[site var form cmp cri skip].each { |k| c[k] = ref[k] }
          unless c[:skip]
            real = stat.pick_val(c)
            res = method('_ope_' + c[:cmp]).call(c[:cri], real)
            c.update(real: real, res: res)
            verbose { c.map { |k, v| format('%s=%s', k, v) }.join(',') }
          end
          c
        end

        # Get Status from Devices via http
        def ___scan
          @spary.each_with_object({}) do |s, hash|
            stat = s[:status]
            st = hash[stat.id] = stat.latest
            verbose { "Scanning #{stat.id} (#{elps_sec(st[:time])})" }
          end
        end

        # Operators
        def _ope_equal(a, b)
          a == b
        end

        def _ope_not(a, b)
          a != b
        end

        def _ope_match(a, b)
          /#{a}/ =~ b ? true : false
        end

        def _ope_unmatch(a, b)
          /#{a}/ !~ b ? true : false
        end
      end
    end
  end
end
