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
      def initialize(stat, sv_stat, valid_keys)
        # Datax#put() will access to header, but get() will access @data
        @record = type?(stat, Record)
        @record.put(:status, 'ready')
        @sv_stat = type?(sv_stat, Prompt)
        @valid_keys = type?(valid_keys, Array)
      end

      # For prompt
      def to_v
        st = @record[:status]
        "(#{st})" + __options
      end

      # return t/f
      def query(cmds)
        @valid_keys.replace(cmds)
        ___judge(___input_tty)
      ensure
        clear
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
          break id if __response(id)
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
