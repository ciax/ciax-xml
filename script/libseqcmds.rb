#!/usr/bin/ruby
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

      def _cmd_mesg(_e, step, _mstat)
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
      def _cmd_bypass(_e, step, mstat)
        return true unless step.skip?
        mstat.result = 'bypass'
        false
      end

      # Enter if condition is unsatisfied (return true)
      # Vars in conditions are changed in this sequence
      # It is used for multiple retry function
      def _cmd_goal(_e, step, _mstat)
        return true unless step.skip?
        # When condition meets skip
        # Enter if test mode
        return @opt.test? if @opt.nonstop?
        _qry_enter?(step)
      end

      def _cmd_check(_e, step, _mstat)
        return true unless step.fail? && _qry_giveup?(step)
        raise Interlock
      end

      def _cmd_verify(_e, step, mstat)
        return true unless step.fail?
        raise mstat[:retry].to_i > 0 ? Verification : Interlock
      end

      def _cmd_wait(_e, step, _mstat)
        return true unless step.timeout? && _qry_giveup?(step)
        raise Interlock
      end

      def _cmd_sleep(_e, step, _mstat)
        step.sleeping
        true
      end

      def _cmd_exec(e, step, _mstat)
        step.exec if step.exec? && _qry_exec?(step)
        show_fg step.indent_s(5)
        @sv_stat.push(:run, e[:site]).cmt unless
          @sv_stat.upd.get(:run).include?(e[:site])
        true
      end

      # return T/F
      def _cmd_cfg(_e, step, _mstat)
        step.exec_wait
      end

      # return T/F
      def _cmd_upd(_e, step, mstat)
        step.exec_wait
      rescue CommError
        mstat.result = __set_err(step)
      end

      # return T/F
      def _cmd_system(_e, step, _mstat)
        step.system if step.exec? && _qry_exec?(step)
        true
      end

      # Return T/F
      def _cmd_select(e, step, mstat)
        var = ___get_stat(e) || cfg_err('No data in status')
        step.result = var
        show_fg step.result_s
        sel = e[:select]
        name = sel[var] || sel['*'] || mcr_err("No option for #{var} ")
        _new_step({ type: 'mcr', args: name }, mstat)
      end

      def _cmd_mcr(e, step, mstat)
        if e[:async] && @submcr_proc.is_a?(Proc)
          step[:id] = @submcr_proc.call(_get_ment(e), @id).id
        else
          ___mcr_fg(e, step, mstat)
        end
        true
      end
    end
  end
end
