#!/usr/bin/ruby
require 'libupd'
require 'libstep'

module CIAX
  module Mcr
    # Element of Record
    class Step
      attr_reader :opt

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
        # Interactive section
        def exec?
          which?('approval', 'dryrun', !@opt.dry?)
        end

        # Execution section
        def async?
          which?('forked', 'entering', /true|1/ =~ self[:async])
        end

        def sleeping
          s = self[:val] || return
          progress(s)
          self.result = 'slept'
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
          self.result = 'pass'
          false
        end

        # Not Condition Step, returns t/f
        def which?(tmsg, fmsg, tf)
          self.result = tf ? tmsg : fmsg
          tf
        end

        def result=(msg)
          self[:result] = msg.downcase
        ensure
          cmt
        end

        def progress(total, &cond)
          itv = @opt.log? ? 1 : 0
          total.to_i.times do |n| # gives number or nil(if break)
            self[:count] = n + 1
            break if cond && yield
            Kernel.sleep itv
            dot if Msg.fg?
            cmt
          end
        end
      end
    end
  end
end