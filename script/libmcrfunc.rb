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
      # Step functions included in Seq
      #  Continue sequence if returns nil

      private

      def _mesg(_e, step, _mstat)
        step.upd
        @qry.query(['ok'], step)
        true
      end

      def _goal(_e, step, mstat)
        return true unless step.skip? # Entering
        return true if @dummy && @qry.query(%w(pass enter), step)
        mstat[:result] = 'skipped'
        false
      end

      def _check(_e, step, mstat)
        return true unless step.fail? && _giveup?(step)
        mstat[:result] = 'error'
        fail Interlock
      end

      def _verify(_e, step, mstat)
        return true unless step.fail? && _giveup?(step)
        mstat[:result] = 'failed'
        fail Verification
      end

      def _wait(e, step, mstat)
        if (s = e[:sleep])
          step.sleeping(s)
          return true
        end
        return true unless step.timeout? && _giveup?(step)
        mstat[:result] = 'timeout'
        fail Interlock
      end

      def _exec(e, step, _mstat)
        _exe_site(e) if step.exec? && @qry.query(%w(exec skip), step)
        @sv_stat.push(:run, e[:site])
        true
      end

      def _cfg(e, step, _mstat)
        step.upd
        _exe_site(e)
        true
      end

      def _upd(e, step, _mstat)
        step.upd
        e[:args] = ['upd']
        _exe_site(e)
        true
      end

      def _select(e, step, mstat)
        var = _get_stat(e)
        cfg_err('No data in status') unless var
        step[:result] = var
        step.upd
        sel = e[:select]
        me = { type: 'mcr', args: sel[var] || sel['*'] }
        sub_macro([me], mstat)
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
        step.upd
        begin
          res = sub_macro(_get_ment(e)[:sequence], step)
          return res if res
          mstat[:result] = 'failed'
          fail Interlock
        rescue Verification
          _mcr_retry(e, step, mstat) || retry
        end
      end

      def _mcr_retry(e, step, mstat)
        if step[:retry]
          step[:action] = 'retry'
          @count += 1
          if @count <= step[:retry].to_i
            step = @record.add_step(e, @depth)
            step[:count] = @count
            step.show_title.upd
            return
          end
        else
          mstat[:result] = 'failed'
        end
        true
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
