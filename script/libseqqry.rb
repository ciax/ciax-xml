#!/usr/bin/env ruby
require 'readline'
require 'thread'
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
        @que_cmd = Queue.new
        @que_res = Queue.new
      end

      # For prompt
      def to_v
        st = @record[:status]
        "(#{st})" + __options
      end

      # Communicate with forked macro
      def reply(ans)
        if @record[:status] == 'query'
          @que_cmd << ans
          @que_res.pop
        else
          'IGNORE'
        end
      end

      # return t/f
      def query(cmds, step)
        return step.put(:action, 'nonstop') if @sv_stat.upd.up?(:nonstop)
        res = ___get_ans(step, cmds)
        ___judge(res)
      ensure
        clear
      end

      def clear
        @valid_keys.clear
        self
      end

      private

      def ___get_ans(step, cmds)
        @valid_keys.replace(cmds)
        @record.put(:option, cmds).put(:status, 'query').cmt
        res = Msg.fg? ? ___input_tty : ___input_que
        @record.put(:status, 'run').delete(:option)
        step.put(:action, res).cmt
        res
      end

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

      def ___input_que
        loop do
          id = @que_cmd.pop.split(/[ :]/).first
          break id if __response(id)
        end
      end

      def __response(id)
        if @valid_keys.include?(id)
          @que_res << 'ACCEPT'
          return id
        elsif !id
          @que_res << ''
        else
          @que_res << 'INVALID'
        end
        false
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
