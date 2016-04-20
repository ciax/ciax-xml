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
        _show step.result
        @qry.query(['ok'], step)
        true
      end

      def _goal(_e, step, mstat)
        return true unless step.skip? # Entering
        return true if @dummy && @qry.query(%w(pass enter), step)
        mstat[:result] = 'skipped'
        false
      ensure
        _show step.result
      end

      def _check(_e, step, mstat)
        return true unless step.fail? && _giveup?(step)
        mstat[:result] = 'error'
        fail Interlock
      ensure
        _show step.result
      end

      def _verify(_e, step, mstat)
        return true unless step.fail? && _giveup?(step)
        mstat[:result] = 'failed'
        fail Verification
      ensure
        _show step.result
      end

      def _wait(_e, step, mstat)
        return true if step.sleeping
        return true unless step.timeout? && _giveup?(step)
        mstat[:result] = 'timeout'
        fail Interlock
      ensure
        _show step.result
      end

      def _exec(e, step, _mstat)
        _exe_site(e) if step.exec? && @qry.query(%w(exec skip), step)
        @sv_stat.push(:run, e[:site])
        true
      ensure
        _show step.result
      end

      def _cfg(e, step, _mstat)
        _show step.result
        _exe_site(e)
        true
      end

      def _upd(e, step, _mstat)
        _show step.result
        _get_site(e).exe(['upd']).waiting
        true
      end

      def _select(e, step, mstat)
        var = _get_stat(e)
        cfg_err('No data in status') unless var
        step[:result] = var
        _show step.result
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
        _show step.result
        begin
          res = sub_macro(_get_ment(e)[:sequence], step)
          return res if res
          mstat[:result] = 'failed'
          fail Interlock
        rescue Verification
          _mcr_retry(e, step, mstat) && retry
        end
      end

      def _mcr_retry(e, step, mstat)
        if step[:retry]
          step[:action] = 'retry'
          _count_up(e, step)
        else
          mstat[:result] = 'failed'
          false
        end
      end

      def _count_up(e, step)
        @count += 1
        return if @count > step[:retry].to_i # exit
        step = @record.add_step(e, @depth)
        step[:count] = @count
        step.show_title.cmt # continue
      end

      # Sub Method
      def _get_site(e)
        @cfg[:dev_list].get(e[:site]).sub
      end

      def _exe_site(e)
        _get_site(e).exe(e[:args])
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
