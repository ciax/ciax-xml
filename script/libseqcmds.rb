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

      def _mesg(_e, step, _mstat)
        _show
        @qry.query(['ok'], step)
        true
      end

      # skip? | dummy | return
      #   o   |   o   |  @qry
      #   o   |   x   |  false
      #   x   |   o   |  true (Entering)
      #   x   |   x   |  true (Entering)

      # Bypass if condition is satisfied (return false)
      # Vars in conditions are not related in this sequence
      def _bypass(_e, step, mstat)
        return true unless step.skip?
        mstat[:result] = 'bypass'
        false
      end

      # Enter if condition is unsatisfied (return true)
      # Vars in conditions are changed in this sequence
      # It is used for multiple retry function
      def _goal(_e, step, mstat)
        return true unless step.skip?
        return true if step.dummy && @qry.query(%w(pass enter), step)
        mstat[:result] = 'skipped'
        false
      end

      def _check(_e, step, mstat)
        return true unless step.fail? && _giveup?(step)
        mstat[:result] = 'failed'
        raise Interlock
      end

      def _verify(_e, step, mstat)
        return true unless step.fail? && _giveup?(step)
        mstat[:result] = 'failed'
        raise Verification
      end

      def _wait(_e, step, mstat)
        return true unless step.timeout? && _giveup?(step)
        mstat[:result] = 'timeout'
        raise Interlock
      end

      def _sleep(_e, step, _mstat)
        step.sleeping
        true
      end

      def _exec(e, step, _mstat)
        if step.exec? && @qry.query(%w(exec skip), step)
          step.set_result(_exe_site(e))
        end
        @sv_stat.push(:run, e[:site]).cmt unless
          @sv_stat.upd.get(:run).include?(e[:site])
        true
      end

      def _cfg(e, _step, _mstat)
        _show
        _exe_site(e)
        true
      end

      def _upd(e, _step, _mstat)
        _show
        _get_site(e).exe(['upd'], 'macro').wait_ready
        true
      end

      def _system(e, step, _mstat)
        return true unless step.exec?
        step.set_result(`#{e[:val]}`.chomp)
        true
      end

      # Return T/F
      def _select(e, step, mstat)
        var = _get_stat(e) || cfg_err('No data in status')
        step[:result] = var
        _show step.result
        sel = e[:select]
        name = sel[var] || sel['*'] || cfg_err("No option for #{var} ")
        do_step({ type: 'mcr', args: name }, mstat)
      end

      def _mcr(e, step, mstat)
        if e[:async] && @submcr_proc.is_a?(Proc)
          step[:id] = @submcr_proc.call(_get_ment(e), @id).id
        else
          _mcr_fg(e, step, mstat)
        end
      end
    end
  end
end
