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
      # rem = Remote::Domain
      def initialize(stat, sv_stat, rem, &res_proc)
        # Datax#put() will access to header, but get() will access @data
        @record = type?(stat, Record)
        @record.put(:status, 'ready')
        @sv_stat = type?(sv_stat, Prompt)
        @rem = type?(rem, Remote::Domain)
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
        @rem.int.valid_repl(opt)
        _judge(_input_tty)
      ensure
        clear
      end

      def clear
        @rem.int.valid_clear
        self
      end

      private

      def __options
        @rem.int.valid_view
      end

      def _input_tty
        Readline.completion_proc = proc { |w| @rem.valid_comp(w) }
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
