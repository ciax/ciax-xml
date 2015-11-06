#!/usr/bin/ruby
require 'thread'
require 'libdatax'

module CIAX
  # Macro layer
  module Mcr
    # Sequencer module
    module Seq
      # Query options
      class Query
        include Msg
        # Record should have ['option'] key
        def initialize(stat)
          # Datax#put() will access to header, but get() will access @data
          @stat = type?(stat, Datax)
          @stat.put('status', 'ready')
          @stat.put('option', [])
          @que_cmd = Queue.new
          @que_res = Queue.new
        end

        def to_v
          st = @stat['status']
          "(#{st})" + _options
        end

        # Communicate with forked macro
        def reply(ans)
          if @stat['status'] == 'query'
            @que_cmd << ans
            @que_res.pop
          else
            'IGNORE'
          end
        end

        def query(cmds, sub_stat)
          return true if OPT['n']
          @stat['option'].replace(cmds)
          @stat.put('status', 'query')
          res = Msg.fg? ? _input_tty(cmds, sub_stat) : _input_que(cmds)
          sub_stat.put('action', res)
          @stat['option'].clear
          @stat.put('status', 'run')
          _judge(res)
        end

        private

        def _options
          optlist(@stat['option'])
        end

        def _input_tty(cmds, sub_stat)
          Readline.completion_proc = proc { |word| cmds.grep(/^#{word}/) }
          loop do
            prom = sub_stat.body(_options)
            line = Readline.readline(prom, true)
            break 'interrupt' unless line
            id = line.rstrip
            break id if _response(cmds, id)
          end
        end

        def _input_que(cmds)
          loop do
            id = @que_cmd.pop.split(/[ :]/).first
            break id if _response(cmds, id)
          end
        end

        def _response(cmds, id)
          if cmds.include?(id)
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
end
