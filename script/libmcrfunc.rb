#!/usr/bin/ruby
require 'libmcrcmd'
require 'libmcrrsp'
require 'libwatexe'
require 'libmcrqry'

module CIAX
  # Macro Layer
  module Mcr
    # Sub Class
    class Seq
      # Step functions

      private

      def _mesg(_e, step, _mstat)
        step.ok?
        @qry.query(['ok'], step)
        false
      end

      def _goal(_e, step, mstat)
        return unless step.skip?
        return if OPT.test? && !@qry.query(%w(skip force), step)
        mstat[:result] = 'skipped'
      end

      def _check(_e, step, mstat)
        return unless step.fail? && _giveup?(step)
        mstat[:result] = 'error'
        fail Interlock
      end

      alias_method :_verify, :_check

      def _wait(e, step, mstat)
        if (s = e[:sleep])
          step.sleeping(s)
          return
        end
        return unless step.timeout? && _giveup?(step)
        mstat[:result] = 'timeout'
        fail Interlock
      end

      def _exec(e, step, _mstat)
        _exe_site(e) if step.exec? && @qry.query(%w(exec pass), step)
        @sv_stat.push(:run, e[:site])
        false
      end

      def _cfg(e, step, _mstat)
        step.ok?
        _exe_site(e)
        false
      end

      def _upd(e, step, _mstat)
        step.ok?
        e[:args] = ['upd']
        _exe_site(e)
        false
      end

      def _mcr(e, step, _mstat)
        seq = @cfg.ancestor(2).set_cmd(e[:args])
        if step.async? && @submcr_proc.is_a?(Proc)
          step[:id] = @submcr_proc.call(seq, @id).id
        else
          res = _mcr_fg(e, seq, step)
          fail Interlock unless res
        end
        false
      end

      def _select(e, step, _mstat)
        var = _get_stat(e)
        e[:args] = e[:select][var]
        _mcr(e, step, nil)
      end

      # Sub Method
      def _mcr_fg(e, seq, step)
        (e[:retry] || 1).to_i.times do
          res = sub_macro(seq, step)
          return res if res
          step[:action] = 'retry'
        end
        nil
      end

      def _get_site(e)
        @cfg[:dev_list].get(e[:site])
      end

      def _exe_site(e)
        _get_site(e).exe(e[:args], 'macro').join('macro')
      end

      def _get_stat(e)
        _get_site(e).sub.stat[e[:form].to_sym][e[:var]]
      end

      def _giveup?(step)
        @qry.query(%w(drop force retry), step)
      end
    end
  end
end
