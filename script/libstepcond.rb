#!/usr/bin/env ruby
require 'libstepproc'
require 'libwatdic'

module CIAX
  # Macro Layer
  module Mcr
    # Element of Record
    class Step
      # Step condition module
      module Condition
        private

        def __get_real(stat, h)
          warning('No form specified') unless h[:form]
          # form = 'data', 'class' or 'msg' in Status
          form = (h[:form] || :data).to_sym
          var = h[:var]
          data = stat[form]
          warning('No [%s] in Status[%s]', var, form) unless data.key?(var)
          data[var]
        end

        def ___condition(stat, h)
          c = {}
          %i(site var form cmp cri skip).each { |k| c[k] = h[k] }
          unless c[:skip]
            real = __get_real(stat, c)
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
