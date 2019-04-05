#!/usr/bin/env ruby
require 'libstepproc'
require 'libwatdic'

module CIAX
  # Macro Layer
  module Mcr
    # Element of Record
    class Step
      # Extension method
      module Processor
        def ext_local_dev(dev_dic)
          extend(Device).ext_local_dev(dev_dic)
        end
      end

      # Step condition module
      module Condition
        private

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

      # Check Device Status
      module Device
        include Condition
        def self.extended(obj)
          Msg.type?(obj, Processor)
        end

        def ext_local_dev(dev_dic)
          @dev_dic = type?(dev_dic, Wat::ExeDic)
          # App::Exe dic used in this Step
          if (@condition = delete(:cond))
            sites = @condition.map { |h| h[:site] }.uniq
            @exes = sites.map { |s| @dev_dic.get(s) }
          end
          self
        end

        def exec
          _set_res(_exe_site.to_s)
        end

        def exec_wait
          _show_res(_exe_site.wait_ready)
        end

        def system
          _show_res(`#{self[:val]}`.chomp)
        end

        def select_args
          stat = @dev_dic.get(self[:site]).sub.stat
          super(__get_real(stat, self))
        end

        # Conditional judgment section
        def skip?
          wait_ready_all
          super(__all_conds?)
        end

        def fail?
          wait_ready_all
          super(!__all_conds?)
        end

        # wait for active?==true, then wait for cond
        # Need to wait inactive.
        # Otherwise macro proceed on bad condition (before valid_keys recovery).
        def timeout?
          tf = progress { active? } ||
               progress { __all_conds? } ||
               progress { !active? }
          which?('timeout', 'pass', tf)
        end

        # obj.waitbusy -> looking at Prompt[:busy]
        # obj.stat -> looking at Status

        def active?
          @exes.all? { |e| e.stat.active? }
        end

        # Blocking during busy. (for interlock check)
        def wait_ready_all
          @exes.each(&:wait_ready)
          self
        end

        def progress(var = nil)
          var ||= self[:retry].to_i - self[:count].to_i
          return super(var) unless defined? yield
          super(var) do
            @exes.all? { |e| e.stat.updating? }
            yield
          end
        end

        private

        def _exe_site
          @dev_dic.get(self[:site]).exe(self[:args], 'macro')
        end

        def __all_conds?
          stats = ___scan
          conds = @condition.map do |h|
            ___condition(stats[h[:site]], h)
          end
          self[:conditions] = conds
          conds.all? { |h| h[:skip] || h[:res] }
        end

        # Get status from Devices via http
        def ___scan
          @exes.each_with_object({}) do |exe, hash|
            st = hash[exe.id] = exe.sub.stat.latest
            verbose { "Scanning #{exe.id} (#{elps_sec(st[:time])})" }
          end
        end

        def __get_real(stat, h)
          warning('No form specified') unless h[:form]
          # form = 'data', 'class' or 'msg' in Status
          form = (h[:form] || :data).to_sym
          var = h[:var]
          data = stat[form]
          warning('No [%s] in Status[%s]', var, form) unless data.key?(var)
          data[var]
        end
      end
    end
  end
end
