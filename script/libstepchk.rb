#!/usr/bin/ruby
require 'libstep'

module CIAX
  module Mcr
    # Element of Record
    class Step
      def ext_local_checker(db, depth, opt)
        extend(Checker).ext_local_checker(db, depth, opt)
      end

      # Step Checker
      module Checker
        def self.extended(obj)
          Msg.type?(obj, Step)
        end

        def ext_local_checker(db, depth, opt)
          update db
          self[:depth] = depth
          @opt = opt
          # Prevent time update on step
          @cmt_procs.clear
          self
        end

        #### In Drive mode
        def exec
          _set_res('dummy')
        end

        def exec_wait
          exec
        end

        def system
          exec
        end

        # Interactive section
        def exec?
          which?('approval', 'dryrun', !@opt.dry?)
        end

        # Execution section
        def async?
          which?('forked', 'entering', /true|1/ =~ self[:async])
        end

        def sleeping
          progress(self[:val])
          _set_res('slept')
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
          _set_res('pass')
          false
        end

        # Not Condition Step, returns t/f
        def which?(tmsg, fmsg, tf)
          _set_res(tf ? tmsg : fmsg)
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
      end
    end
  end
end
