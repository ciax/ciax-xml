#!/usr/bin/ruby
require 'libvarx'
require 'libmcrprt'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Record
    class Record < Varx
      # Level [0] Step, [1] Record & Item, [2] Group, [3] Domain, [4] Command
      def initialize(id = nil) # Session ID for Loading
        super('record')
        self[:id] = id || self[:time].to_s # Session ID
        self[:steps] = Arrayx.new
        self[:status] = 'ready'
        self[:result] = 'busy'
      end

      def to_v
        msg = title
        self[:steps].each do |i|
          i.extend(PrtShare) unless i.is_a? PrtShare
          msg << i.title + i.result
        end
        msg << " (#{self[:result]}) #{step_num}"
      end

      def step_num
        "[#{self[:steps].size}/#{self[:original_steps]}]"
      end

      def busy?
        self[:result] == 'busy'
      end

      def last
        self[:steps].last
      end

      def title
        date = Time.at((self[:time] / 1000).round)
        Msg.colorize('MACRO', 3) + format(":%s (%s)\n", self[:label], date)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('r')
      OPT.usage '(-r) [id] (< file)' if STDIN.tty? && ARGV.size < 1
      if STDIN.tty?
        puts Record.new(ARGV.shift).ext_file
      else
        puts Record.new.read
      end
    end
  end
end
