#!/usr/bin/env ruby
require 'libseqfunc'

module CIAX
  # Macro Layer
  module Mcr
    # Sub Class
    class Sequencer
      # Step functions included in Sequencer
      #  Each method returns T/F
      #  Continue sequence if result is true

      private

      def _cmd_mesg(step, _mstat)
        @qry.query(['ok'], step)
        true
      end

      # skip? | test  | return
      #   o   |   o   |  @qry
      #   o   |   x   |  false
      #   x   |   o   |  true (Entering)
      #   x   |   x   |  true (Entering)

      # Bypass if condition is satisfied (return false)
      # Vars in conditions are not related in this sequence
      def _cmd_bypass(step, mstat)
        return true unless step.skip?
        mstat.result = 'bypass'
        false
      end

      # Enter if condition is unsatisfied (return true)
      # Vars in conditions are changed in this sequence
      # It is used for multiple retry function
      def _cmd_goal(step, _mstat)
        return true unless step.skip?
        # When condition meets skip
        # Enter if test mode
        return @opt.test? if @opt.nonstop?
        _qry_enter?(step)
      end

      def _cmd_check(step, _mstat)
        return true unless step.fail? && _qry_giveup?(step)
        raise Interlock
      end

      def _cmd_verify(step, mstat)
        return true unless step.fail?
        raise Verification if mstat[:retry].to_i > 0
        return true unless _qry_giveup?(step)
        raise Interlock
      end

      def _cmd_wait(step, _mstat)
        return true unless step.timeout? && _qry_giveup?(step)
        raise Interlock
      end

      def _cmd_sleep(step, _mstat)
        step.sleeping
        true
      end

      def _cmd_exec(step, _mstat)
        step.exec if step.exec? && _qry_exec?(step)
        site = step[:site]
        @sv_stat.push(:run, site).cmt unless
          @sv_stat.upd.get(:run).include?(site)
        true
      end

      # return T/F
      def _cmd_cfg(step, _mstat)
        step.exec_wait
      end

      # return T/F
      def _cmd_upd(step, mstat)
        step.exec_wait
      rescue CommError
        mstat.result = __set_err(step)
      end

      # return T/F
      def _cmd_system(step, _mstat)
        step.system if step.exec? && _qry_exec?(step)
        true
      end

      # Return T/F
      def _cmd_select(step, _mstat)
        ___mcr_exe(step.select_args, step)
      end

      def _cmd_mcr(step, _mstat)
        ___mcr_exe(step[:args], step)
      end
    end
  end
end
