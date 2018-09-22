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
          _sub_macro(_get_ment(e), step) || raise(Interlock)
        rescue Verification
          step.result = 'failed'
          if step[:retry]
            ___count_up(e, step)
            step = ___new_macro(e)
            retry
          end
        end
      ensure
        mstat.result = step.result
      end

      # Sub for _mcr_fg()
      def __show_begin(step)
        show_fg step.title_s
        show_fg Msg.colorize('(Retry)', 17) if @count.to_i > 1
        show_fg Msg.colorize(" {\n", 1)
      end

      def __show_end(step, res = nil)
        show_fg step.indent_s(4) + Msg.colorize(' }', 1)
        show_fg step.result_s if res
      end

      # Sub for _mcr_retry()
      def ___count_up(_e, step)
        @count += 1
        step[:action] = 'retry'
        __show_end(step, true)
        raise Interlock if @count > step[:retry].to_i # exit
      end

      def ___new_macro(e)
        newstep = @record.add_step(e, @depth)
        newstep[:count] = @count
        newstep.cmt # continue
        __show_begin(newstep)
        sleep newstep[:wait].to_i
        newstep
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
