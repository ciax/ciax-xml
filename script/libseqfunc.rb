#!/usr/bin/ruby
require 'libmcrcmd'
require 'librecproc'
require 'libseqqry'

module CIAX
  # Macro Layer
  module Mcr
    # Sub Class
    class Sequencer
      ERR_CODE = {
        verification: 'incomplete',
        interlock: 'failed',
        interrupt: 'interrupted',
        commerror: 'comerr'
      }.freeze

      private

      # Sub for for cmd_mcr()
      def ___mcr_fg(e, step, _mstat)
        __enc_begin
        step[:count] = 1 if step[:retry]
        ___mcr_trial(e, step)
      end

      # Sub for _mcr_fg()
      def ___mcr_trial(e, step)
        _sequencer(_get_ment(e), step)
        __enc_end(step)
        show_fg step.result_s
      rescue Verification
        __set_err(step)
        count = ___count_retry(step)
        step = ___new_macro(e, count)
        sleep step[:wait].to_i
        retry
      end

      # Sub for _mcr_trial()
      def ___count_retry(step)
        count = step[:count].to_i
        __enc_end(step)
        if count >= step[:retry].to_i
          raise Interlock if _qry_giveup?(step)
        else
          show_fg step.result_s
        end
        step[:action] = 'retry'
        count
      end

      def ___new_macro(e, count)
        newstep = @record.add_step(e, @depth)
        newstep[:count] = count + 1
        show_fg newstep.title_s
        show_fg Msg.colorize("(Retry #{count})", 1)
        __enc_begin
        newstep.cmt # continue
      end

      def __enc_begin
        show_fg Msg.colorize(" {\n", 1)
      end

      def __enc_end(step)
        show_fg step.indent_s(4) + Msg.colorize(' }', 1)
      end

      def __set_err(step)
        ek = $ERROR_INFO.class.to_s.split(':').last.downcase
        step.result = ERR_CODE[ek.to_sym] || ek
      end

      # Sub for cmd_select()
      def ___get_stat(e)
        _get_site(e).stat[e[:form].to_sym][e[:var]]
      end

      ## Shared Methods
      def _get_site(e)
        @dev_list.get(e[:site])
      end

      def _exe_site(e)
        _get_site(e).exe(e[:args], 'macro')
      end

      # Mcr::Entity
      def _get_ment(e)
        @cfg[:index].set_cmd(e[:args])
      end

      # Query
      def _qry_giveup?(step)
        show_fg step.result_s
        @qry.query(%w(drop force retry), step)
      end

      def _qry_enter?(step)
        show_fg step.result_s
        step.result = 'enter' if @qry.query(%w(pass enter), step)
      end

      def _qry_exec?(step)
        show_fg step.result_s
        @qry.query(%w(exec skip), step)
      end
    end
  end
end
