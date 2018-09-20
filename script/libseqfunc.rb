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
        @count = step[:count] = 1 if step[:retry]
        begin
          _sub_macro(_get_ment(e)[:sequence], step) || raise(Interlock)
        rescue Verification
          ___mcr_retry(e, step, mstat) && retry
        end
      ensure
        mstat.result = step.result
      end

      # Sub for _mcr_fg()
      def ___mcr_retry(e, step, mstat)
        if step[:retry] && ___count_up(e, step)
          __show_end(step, true)
          __show_begin(step)
          true
        else
          mstat.result = 'failed'
          false
        end
      end

      def __show_begin(step = nil)
        show_fg step.title_s + '(retry)' if step
        show_fg Msg.colorize("{\n", 1)
      end

      def __show_end(step, res = nil)
        show_fg step.indent_s(4) + Msg.colorize('}', 1)
        show_fg step.result_s if res
      end

      # Sub for _mcr_retry()
      def ___count_up(e, step)
        @count += 1
        step[:action] = 'retry'
        raise Interlock if @count > step[:retry].to_i # exit
        newstep = @record.add_step(e, @depth)
        newstep[:count] = @count
        newstep.cmt # continue
        sleep step[:wait].to_i
        true
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
