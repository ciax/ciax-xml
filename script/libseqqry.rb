#!/usr/bin/env ruby
require 'libmcrqry'
require 'thread'

module CIAX
  # Macro layer
  module Mcr
    # Query options
    class Reply < Query
      include Msg
      def initialize(stat, sv_stat, valid_keys)
        # Datax#put() will access to header, but get() will access @data
        super
        @que_cmd = Queue.new
        @que_res = Queue.new
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
        @record.put(:option, cmds).put(:status, 'query').cmt
        @valid_keys.replace(cmds)
        res = Msg.fg? ? ___input_tty : ___input_que
        step.put(:action, res).cmt
        ___judge(res)
      ensure
        clear
      end

      private

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
    end
  end
end
