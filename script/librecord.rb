#!/usr/bin/ruby
require 'libdatax'
require 'libmcrprt'

module CIAX
  module Mcr
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
        date = Time.at((self['time'] / 1000).round)
        msg = Msg.color('MACRO', 3) + ":#{self['label']} (#{date})\n"
        @data.each { |i| msg << i.title + i.result }
        msg << " (#{self['result']})" if self['result']
        msg << " [#{@data.size}/#{self['original_steps']}]"
        msg
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('r')
      OPT.usage '(-r) < record_file' if STDIN.tty?
      puts Record.new.read
    end
  end
end
