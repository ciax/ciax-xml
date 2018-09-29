#!/usr/bin/ruby
require 'libmcrcmd'
require 'librecproc'
require 'libseqqry'

module CIAX
  # Macro Layer
  module Mcr
    # Sub Class
    class Sequencer
      private

      # Sub for for cmd_mcr()
      def ___mcr_fg(e, step, mstat)
        __enc_begin
        step[:count] = 1 if step[:retry]
        ___mcr_trial(e, step)
      rescue
        mstat.result = step.result
        raise
      end

      # Sub for _mcr_fg()
      def ___mcr_trial(e, step)
        _sequencer(_get_ment(e), step) || raise(Interlock)
        __enc_end(step)
        step.result = 'complete'
      rescue Verification
        __enc_end(step)
        count = ___count_retry(step)
        return unless count
        step = ___new_macro(e, count)
        sleep step[:wait].to_i
        retry
      end

      def ___count_retry(step)
        show_fg step.result_s
        max = step[:retry]
        return unless max
        count = step[:count].to_i
        raise Interlock if count >= max.to_i # exit
        step[:action] = 'retry'
        count
      end

      def __enc_begin
        show_fg Msg.colorize(" {\n", 1)
      end

      def __enc_end(step)
        show_fg step.indent_s(4) + Msg.colorize(' }', 1)
      end

      # Sub for _mcr_retry()
      def ___new_macro(e, count)
        newstep = @record.add_step(e, @depth)
        newstep[:count] = count + 1
        show_fg newstep.title_s
        show_fg Msg.colorize("(Retry #{count})", 1)
        __enc_begin
        newstep.cmt # continue
      end

      # Sub for cmd_select()
      def ___get_stat(e)
        _get_site(e).stat[e[:form].to_sym][e[:var]]
      end

      ## Shared Methods
      def _get_site(e)
        @dev_list.get(e[:site]).sub
      end

      def _exe_site(e)
        _get_site(e).exe(e[:args], 'macro')
      end

      # Mcr::Entity
      def _get_ment(e)
        @cfg[:index].set_cmd(e[:args])
      end

      def _giveup?(step)
        @qry.query(%w(drop force retry), step)
      end
    end
  end
end
