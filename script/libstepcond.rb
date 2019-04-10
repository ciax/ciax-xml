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
        def initialize(cond)
          @conditions = type?(cond, Array)
        end

        # Get condition result Array
        def get_cond(stats)
          @conditions.map do |ref|
            ___condition(stats[ref[:site]], ref)
          end
        end

        # Getting Scanning sites
        def sites
          @conditions.map { |ref| ref[:site] }.uniq
        end

        # Getting real value in [data:id]
        def pick_val(stat, ref)
          warning('No form specified') unless ref[:form]
          # form = 'data', 'class' or 'msg' in Status
          form = (ref[:form] || :data).to_sym
          var = ref[:var]
          data = stat[form]
          warning('No [%s] in Status[%s]', var, form) unless data.key?(var)
          data[var]
        end

        private

        def ___condition(stat, ref)
          c = {}
          %i(site var form cmp cri skip).each { |k| c[k] = ref[k] }
          unless c[:skip]
            real = pick_val(stat, c)
            res = method('_ope_' + c[:cmp]).call(c[:cri], real)
            c.update(real: real, res: res)
            verbose { c.map { |k, v| format('%s=%s', k, v) }.join(',') }
          end
          c
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
