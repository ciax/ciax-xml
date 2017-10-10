#!/usr/bin/ruby
require 'libmcrcmd'
require 'librecrsp'
require 'libwatlist'
require 'libseqqry'

module CIAX
  # Macro Layer
  module Mcr
    # Sub Class
    module SeqFunc
      # Step functions included in Sequencer
      #  Continue sequence if returns nil

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

      def _select(e, step, mstat)
        var = _get_stat(e)
        cfg_err('No data in status') unless var
        step[:result] = var
        _show step.result
        sel = e[:select]
        me = { type: 'mcr', args: sel[var] || sel['*'] }
        do_step(me, mstat)
      end

      def _mcr(e, step, mstat)
        if e[:async] && @submcr_proc.is_a?(Proc)
          step[:id] = @submcr_proc.call(_get_ment(e), @id).id
        else
          _mcr_fg(e, step, mstat)
        end
      end

      def _mcr_fg(e, step, mstat)
        @count = step[:count] = 1 if step[:retry]
        _show step.result
        begin
          res = sub_macro(_get_ment(e)[:sequence], step)
          return res if res
          mstat[:result] = step[:result]
          raise Interlock
        rescue Verification
          _mcr_retry(e, step, mstat) && retry
        end
      end

      def _mcr_retry(e, step, mstat)
        return true if step[:retry] && _count_up(e, step)
        mstat[:result] = 'failed'
        false
      end

      def _count_up(e, step)
        @count += 1
        step[:action] = 'retry'
        return false if @count > step[:retry].to_i # exit
        newstep = @record.add_step(e, @depth)
        newstep[:count] = @count
        newstep.cmt # continue
        sleep step[:wait].to_i
        true
      end

      # Sub Method
      def _get_site(e)
        @cfg[:dev_list].get(e[:site]).sub
      end

      def _exe_site(e)
        _get_site(e).exe(e[:args], 'macro').to_s.downcase
      end

      def _get_stat(e)
        _get_site(e).stat[e[:form].to_sym][e[:var]]
      end

      # Mcr::Entity
      def _get_ment(e)
        @cfg.ancestor(2).set_cmd(e[:args])
      end

      def _giveup?(step)
        @qry.query(%w(drop force retry), step)
      end
    end
  end
end
