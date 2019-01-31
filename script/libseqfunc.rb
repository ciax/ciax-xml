#!/usr/bin/env ruby
require 'libmcrcmd'
require 'librecproc'

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

      def ___mcr_exe(args, mstep)
        ment = @cfg[:index].set_cmd(args)
        ___mcr_bg(ment, mstep) || ___mcr_fg(ment, mstep)
        true
      end

      def ___mcr_bg(ment, mstep)
        return unless mstep[:async] && @submcr_proc.is_a?(Proc)
        # adding new macro to @rec_dic, :pid = parent id
        sent = ment.gen(self).update(pid: @id)
        mstep[:id] = @submcr_proc.call(sent).id
      end

      # Sub for for cmd_mcr()
      def ___mcr_fg(ment, mstep)
        __enc_begin
        mstep[:count] = 1 if mstep[:retry]
        ___mcr_trial(ment, mstep)
      end

      # Sub for _mcr_fg()
      def ___mcr_trial(ment, mstep)
        _sequencer(ment, mstep)
        __enc_end(mstep)
      rescue Verification
        mstep = ___mcr_retry(mstep)
        retry
      end

      # Sub for _mcr_trial()
      def ___mcr_retry(mstep)
        __set_err(mstep)
        count = ___count_retry(mstep)
        ___new_macro(mstep, count)
      end

      def ___count_retry(mstep)
        count = mstep[:count].to_i
        __enc_end(mstep)
        raise if count >= mstep[:retry].to_i && _qry_giveup?(mstep)
        mstep[:action] = 'retry'
        sleep mstep[:wait].to_i
        count
      end

      def ___new_macro(mstep, count)
        newmstep = @record.add_step(mstep, @depth)
        newmstep[:count] = count + 1
        show_fg newmstep.title_s
        show_fg Msg.colorize("(Retry #{count})", 1)
        __enc_begin
        newmstep.cmt # continue
      end

      def __enc_begin
        show_fg Msg.colorize(" {\n", 1)
      end

      def __enc_end(mstep)
        show_fg mstep.indent_s(4) + Msg.colorize(' }', 1)
        show_fg mstep.result_s
      end

      def __set_err(mstep)
        ek = $ERROR_INFO.class.to_s.split(':').last.downcase
        mstep.result = ERR_CODE[ek.to_sym] || ek
      end

      # Query
      def _qry_giveup?(cstep)
        @qry.query(%w(drop force retry), cstep)
      end

      def _qry_enter?(cstep)
        cstep.result = 'enter' if @qry.query(%w(pass enter), cstep)
      end

      def _qry_exec?(estep)
        @qry.query(%w(exec skip), estep)
      end
    end
  end
end
