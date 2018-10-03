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
        if step.opt.nonstop?
          return true unless step.opt.prcs?
        else
          return true unless @qry.query(%w(pass enter), step)
        end
        false
      end

      def _cmd_check(_e, step, _mstat)
        return true unless step.fail? && _giveup?(step)
        raise Interlock
      end

      def _cmd_verify(_e, step, mstat)
        return true unless step.fail? && _giveup?(step)
        raise mstat[:retry].to_i > 0 ? Verification : Interlock
      end

      def _cmd_wait(_e, step, _mstat)
        return true unless step.timeout? && _giveup?(step)
        raise Interlock
      end

      def _cmd_sleep(_e, step, _mstat)
        step.sleeping
        true
      end

      def _cmd_exec(e, step, _mstat)
        if step.exec? && @qry.query(%w(exec skip), step)
          step.result = _exe_site(e).to_s
        end
        @sv_stat.push(:run, e[:site]).cmt unless
          @sv_stat.upd.get(:run).include?(e[:site])
        true
      end

      # return T/F
      def _cmd_cfg(e, step, _mstat)
        step.result = _exe_site(e).wait_ready
        show_fg step.result_s
      end

      # return T/F
      def _cmd_upd(e, step, mstat)
        step.result = _exe_site(e).wait_ready
      rescue CommError
        mstat.result = __set_err(step)
      ensure
        show_fg step.result_s
      end

      # return T/F
      def _cmd_system(e, step, _mstat)
        return true unless step.exec?
        step.result = `#{e[:val]}`.chomp
        show_fg step.result_s
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
