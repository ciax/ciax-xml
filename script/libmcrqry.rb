#!/usr/bin/env ruby
require 'readline'
require 'librecord'

module CIAX
  # Macro layer
  module Mcr
    # Query options
    class Query
      include Msg
      # Record should have [:opt] key
      # cgrp_int = Remote::Int::Group
      def initialize(stat, sv_stat, cgrp_int, &res_proc)
        # Datax#put() will access to header, but get() will access @data
        @record = type?(stat, Record)
        @record.put(:status, 'ready')
        @sv_stat = type?(sv_stat, Prompt)
        @cgrp_int = type?(cgrp_int, Remote::Int::Group)
        @res_proc = res_proc
      end

      # For prompt
      def to_v
        st = @record[:status]
        "(#{st})" + __options
      end

      # return t/f
      def query
        opt = @record[:option] || []
        return if opt.empty?
        @cgrp_int.valid_repl(opt)
        _judge(___input_tty)
      ensure
        clear
      end

      def clear
        @cgrp_int.valid_clear
        self
      end

      private

      def __options
        @cgrp_int.valid_view
      end

      def ___input_tty
        Readline.completion_proc = proc { |w| @cgrp_int.valid_comp(w) }
        loop do
          line = Readline.readline(__options, true)
          break 'interrupt' unless line
          id = line.rstrip
          break id if @res_proc.call(id)
        end
      end

      def _judge(res)
        case res
        when 'retry'
          raise(Retry)
        when 'interrupt'
          raise(Interrupt)
        when 'force', 'skip', 'pass'
          false
        else
          true
        end
      end
    end
  end
end
