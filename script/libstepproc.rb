#!/usr/bin/env ruby
require 'libstep'

module CIAX
  module Mcr
    # Element of Record
    class Step
      def ext_processor(db, depth, opt)
        extend(Processor).ext_processor(db, depth, opt)
      end

      # Step Processor
      module Processor
        def self.extended(obj)
          Msg.type?(obj, Step)
        end

        def ext_processor(db, depth, opt)
          update db
          self[:depth] = depth
          @opt = opt
          # Prevent time update on step
          @cmt_procs.clear
          self
        end

        #### In Drive mode
        def exec_wait
          _show_res('dummy')
        end

        def system
          exec_wait
        end

        # returns selected macro args (Array)
        def select_args(key = nil)
          sel = self[:select]
          mcr_err('No select DB') unless sel
          key ||= sel.keys.first
          args = sel[key] || sel['*'] || []
          self[:select] = { key => args }
          mcr_err("No option for #{key} ") if args.empty?
          show_fg select_s
          args
        end

        # Interactive section
        def exec?
          which?('approval', 'dryrun', !@opt.dry? && !@opt.test?)
        end

        # Execution section
        def async?
          which?('forked', 'entering', /true|1/ =~ self[:async])
        end

        def sleeping
          progress(self[:val])
          _show_res('slept')
          true
        end

        # Condition section (fake)
        def skip?(tf = false)
          which?('skip', 'enter', tf)
        end

        def fail?(tf = false)
          which?('failed', 'pass', tf)
        end

        def timeout?
          progress(self[:retry]) { false }
          _show_res('pass')
          false
        end

        # Not Condition Step, returns t/f
        def which?(tmsg, fmsg, tf)
          _show_res(tf ? tmsg : fmsg)
          tf
        end

        def result
          self[:result]
        end

        def result=(msg)
          _set_res(msg)
        end

        # wait until &cond satisfied
        def progress(total, &cond)
          itv = @opt.mcr_log? ? 1 : 0.01
          total.to_i.times do |n| # gives number or nil(if break)
            self[:count] = n + 1
            break if cond && yield
            Kernel.sleep itv
            show_fg('.')
            cmt
          end
        end

        private

        def _set_res(msg)
          self[:result] = msg.downcase
        ensure
          cmt
        end

        def _show_res(msg)
          res = _set_res(msg)
          show_fg result_s
          res
        end
      end
    end
  end
end
