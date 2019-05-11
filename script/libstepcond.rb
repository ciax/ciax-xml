#!/usr/bin/env ruby
require 'libmsg'

module CIAX
  # Macro Layer
  module Mcr
    # Element of Record
    class Step
      # Step condition class
      class Condition
        include Msg
        attr_reader :exes
        def initialize(cond)
          @conditions = type?(cond, Array)
          sites = @conditions.map { |ref| ref[:site] }.uniq
          @exes = sites.map { |id| type?(yield(id), Wat::Exe) }
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
          %i(site var form cmp cri skip).each { |k| c[k] = ref[k] }
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
          @exes.each_with_object({}) do |exe, hash|
            st = hash[exe.id] = exe.sub_exe.stat.latest
            verbose { "Scanning #{exe.id} (#{elps_sec(st[:time])})" }
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
