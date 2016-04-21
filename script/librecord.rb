#!/usr/bin/ruby
require 'libvarx'
require 'libstepprt'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Record
    class Record < Varx
      # Level [0] Step, [1] Record & Item, [2] Group, [3] Domain, [4] Command
      def initialize(id = nil) # Session ID for Loading
        super('record')
        self[:id] = id || self[:time].to_s # Session ID
        update(ver: '0', cid: nil, label: nil, pid: '0', status: 'ready')
        update(result: 'busy', total_steps: 0, total_time: 0, start: 0)
        self[:steps] = Arrayx.new
      end

      def to_v
        msg = title
        self[:steps].each do |i|
          msg << i.to_v
        end
        msg << " (#{self[:result]}) #{step_num}"
      end

      def step_num
        "[#{self[:steps].size}/#{self[:total_steps]}]"
      end

      def busy?
        self[:result] == 'busy'
      end

      def last
        self[:steps].last
      end

      def title
        date = Time.at((self[:time] / 1000).round)
        Msg.colorize('MACRO', 3) +
          format(":%s (%s) [%s]\n", self[:label], self[:cid], date)
      end

      def read(str = nil)
        super
        _ext_steps
        self
      end

      private

      def _ext_steps
        self[:steps].each do |i|
          i.extend(StepPrt).ext_prt(self[:start])
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('< file', 'r') do |_opt, _args|
        fail(InvalidARGS, 'No Input File') if STDIN.tty?
        puts Record.new.read
      end
    end
  end
end
