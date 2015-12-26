#!/usr/bin/ruby
require 'libmcrcmd'
require 'libmcrrsp'
require 'libwatlist'
require 'libmcrqry'

module CIAX
  # Macro Layer
  module Mcr
    # Sub Class
    module Func
      # Step functions
      #  Continue sequence if returns nil
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

      def _verify(_e, step, mstat)
        return unless step.fail?
        mstat[:result] = 'failed'
        fail Verification
      end

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

      def _mcr_async(e, step, mstat)
        if @submcr_proc.is_a?(Proc)
          step[:id] = @submcr_proc.call(_get_ment(e), @id).id
        else
          _mcr(e, step, mstat)
        end
        false
      end

      def _select(e, step, _mstat)
        var = _get_stat(e)
        e[:args] = e[:select][var]
        _mcr(e, step, nil)
      end

      def _mcr(e, step, mstat)
        res = sub_macro(_get_ment(e)[:sequence], step)
        return res if res
        mstat[:result] = 'failed'
        fail Interlock
      end

      def _mcr_retry(e, mstat)
        count = 1
        begin
          step = @record.add_step(e, @depth)
          step[:count] = count
          step.show_title.upd
          _mcr(e, step, mstat)
        rescue Verification
          step[:action] = 'retry'
          count += 1
          retry if count <= step[:retry].to_i
        end
      end

      # Sub Method
      def _get_site(e)
        @cfg[:dev_list].get(e[:site])
      end

      def _exe_site(e)
        _get_site(e).exe(e[:args], 'macro').join('macro')
      end

      def _get_stat(e)
        _get_site(e).sub.stat[e[:form].to_sym][e[:var]]
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
