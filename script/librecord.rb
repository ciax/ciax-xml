#!/usr/bin/ruby
require 'libdatax'
require 'libmcrprt'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Record
    class Record < Datax
      # Level [0] Step, [1] Record & Item, [2] Group, [3] Domain, [4] Command
      def initialize(id = nil) # Session ID for Loading
        super('record', [], 'steps')
        self['id'] = id || self['time'].to_s # Session ID
      end

      def read(json_str = nil)
        super
        @data.each { |i| i.extend(PrtShare) }
        self
      end

      def to_v
        msg = _title
        @data.each { |i| msg << i.title + i.result }
        msg << format(' (%s) [%d/%d]',
                      self['result'], @data.size, self['original_steps'])
      end

      private

      def _title
        date = Time.at((self['time'] / 1000).round)
        Msg.color('MACRO', 3) + format(":%s (%s)\n", self['label'], date)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('r')
      OPT.usage '(-r) < record_file' if STDIN.tty?
      puts Record.new.read
    end
  end
end
