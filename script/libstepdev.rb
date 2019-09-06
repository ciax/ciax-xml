#!/usr/bin/env ruby
require 'libstepproc'
require 'libstepcond'
require 'libwatdic'

module CIAX
  # Macro Layer
  module Mcr
    # Element of Record
    class Step
      # Extension method
      module Processor
        def ext_device(dev_dic)
          extend(Device).ext_device(dev_dic)
        end
      end
      # Check Device Status
      module Device
        def self.extended(obj)
          Msg.type?(obj, Processor)
        end

        # exes: eobj list that is used for macro
        def ext_device(dev_dic)
          @dev_dic = type?(dev_dic, Wat::ExeDic)
          # App::Exe dic used in this Step
          return self unless (condb = delete(:cond))
          @condition = Condition.new(condb) do |s|
            __get_site(s).stat_pool
          end
          self
        end

        def exec_wait
          _show_res(_exe_site.sv_stat.wait_ready)
        end

        def system
          _show_res(`#{self[:val]}`.chomp)
        end

        # step has site,var,form
        def select_args
          stat = __get_site.stat_pool[:status]
          super(stat.pick_val(self))
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
          tf = progress { __all_conds? && !active? }
          which?('timeout', 'pass', tf)
        end

        # obj.waitbusy -> looking at Prompt[:busy]
        # obj.stat -> looking at Status

        def active?
          @condition.active?
        end

        # Blocking during busy. (for interlock check)
        def wait_ready_all
          @condition.wait_ready
          self
        end

        # Until loop
        def progress(var = nil)
          var ||= self[:retry].to_i - self[:count].to_i
          return super(var) unless defined? yield
          super(var) do
            @condition.updating?
            yield
          end
        end

        private

        def __get_site(site = nil)
          @dev_dic.get(site || self[:site])
        end

        def _exe_site
          __get_site.exe(self[:args], 'macro')
        end

        def __all_conds?
          conds = @condition.results
          self[:conditions] = conds
          conds.all? { |h| h[:skip] || h[:res] }
        end
      end
    end
  end
end
