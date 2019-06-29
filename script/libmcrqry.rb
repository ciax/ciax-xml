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
      def initialize(stat, sv_stat, valid_keys, &res_proc)
        # Datax#put() will access to header, but get() will access @data
        @record = type?(stat, Record)
        @record.put(:status, 'ready')
        @sv_stat = type?(sv_stat, Prompt)
        @valid_keys = type?(valid_keys, Array)
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
        @valid_keys.replace(opt)
        ___judge(___input_tty)
      end

      def clear
        @valid_keys.clear
        self
      end

      private

      def __options
        opt_listing(@valid_keys)
      end

      def ___input_tty
        Readline.completion_proc = proc { |w| @valid_keys.grep(/^#{w}/) }
        loop do
          line = Readline.readline(__options, true)
          break 'interrupt' unless line
          id = line.rstrip
          break id if @res_proc.call(id)
        end
      end

      def ___judge(res)
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
