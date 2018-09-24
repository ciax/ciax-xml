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
        show_fg Msg.colorize(' {', 1)
        step[:count] = 1 if step[:retry]
        ___mcr_trial(e, step)
      rescue
        mstat.result = step.result
        raise
      end

      # Sub for _mcr_fg()
      def ___mcr_trial(e, step)
        _sub_macro(_get_ment(e), step) || raise(Interlock)
        __show_end(step, 'complete')
      rescue Verification
        __show_end(step, 'failed')
        return unless step[:retry]
        step = ___new_macro(e, step)
        __show_begin(step)
        sleep step[:wait].to_i
        retry
      end

      def __show_begin(step)
        show_fg step.title_s
        show_fg Msg.colorize("(Retry #{step[:count] - 1})", 1)
        show_fg Msg.colorize(' {', 1)
      end

      def __show_end(step, str)
        show_fg step.indent_s(4) + Msg.colorize(' }', 1)
        step.result = str
      end

      # Sub for _mcr_retry()
      def ___new_macro(e, step)
        step[:action] = 'retry'
        count = step[:count].to_i
        raise Interlock if count >= step[:retry].to_i # exit
        newstep = @record.add_step(e, @depth)
        newstep[:count] = count + 1
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
