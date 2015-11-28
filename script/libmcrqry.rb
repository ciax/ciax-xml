#!/usr/bin/ruby
require 'thread'
require 'libdatax'

module CIAX
  # Macro layer
  module Mcr
    # Query options
    class Query
      include Msg
      # Record should have [:option] key
      def initialize(stat, valid_keys)
        # Datax#put() will access to header, but get() will access @data
        @stat = type?(stat, Datax)
        @stat.put(:status, 'ready')
        @valid_keys = valid_keys
        @que_cmd = Queue.new
        @que_res = Queue.new
      end

      # For prompt
      def to_v
        st = @stat[:status]
        "(#{st})" + _options
      end

      # Communicate with forked macro
      def reply(ans)
        if @stat[:status] == 'query'
          @que_cmd << ans
          @que_res.pop
        else
          'IGNORE'
        end
      end

      def query(cmds, sub_stat)
        return true if OPT[:n]
        @valid_keys.replace(cmds)
        sub_stat.put(:option, cmds)
        @stat.put(:status, 'query')
        res = Msg.fg? ? _input_tty : _input_que
        sub_stat.put(:action, res)
        @stat.put(:status, 'run')
        _judge(res)
      ensure
        @valid_keys.clear
      end

      private

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
        when 'force', 'pass'
          false
        else
          true
        end
      end
    end
  end
end
