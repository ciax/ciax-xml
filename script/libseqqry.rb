#!/usr/bin/ruby
require 'thread'
require 'librecord'

module CIAX
  # Macro layer
  module Mcr
    # Query options
    class Query
      include Msg
      # Record should have [:option] key
      def initialize(stat, sv_stat, valid_keys)
        # Datax#put() will access to header, but get() will access @data
        @record = type?(stat, Record)
        @record.put(:status, 'ready')
        @sv_stat = type?(sv_stat, Prompt)
        @valid_keys = valid_keys
        @que_cmd = Queue.new
        @que_res = Queue.new
      end

      # For prompt
      def to_v
        st = @record[:status]
        "(#{st})" + _options
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

      def query(cmds, step)
        return step.put(:action, 'nonstop') if @sv_stat.up?(:nonstop)
        res = _get_ans(step, cmds)
        _judge(res)
      ensure
        @valid_keys.clear
      end

      private

      def _get_ans(step, cmds)
        @valid_keys.replace(cmds)
        @record.put(:option, cmds)
        step.put(:result, 'query')
        @record.put(:status, 'query')
        res = Msg.fg? ? _input_tty : _input_que
        step.put(:action, res)
        @record.delete(:option)
        @record.put(:status, 'run')
        res
      end

      def _options
        optlist(@valid_keys)
      end

      def _input_tty
        Readline.completion_proc = proc { |w| @valid_keys.grep(/^#{w}/) }
        loop do
          line = Readline.readline(_options, true)
          break 'interrupt' unless line
          id = line.rstrip
          break id if _response(id)
        end
      end

      def _input_que
        loop do
          id = @que_cmd.pop.split(/[ :]/).first
          break id if _response(id)
        end
      end

      def _response(id)
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

      def _judge(res)
        case res
        when 'retry'
          fail(Retry)
        when 'interrupt'
          fail(Interrupt)
        when 'force', 'skip', 'pass'
          false
        else
          true
        end
      end
    end
  end
end
