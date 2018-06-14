#!/usr/bin/ruby
require 'libvarx'
require 'libstepprt'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Record
    class Record < Varx
      attr_accessor :result
      attr_reader :finish_procs
      # Level [0] Step, [1] Record & Item, [2] Group, [3] Domain, [4] Command
      def initialize(id = nil) # Session ID for Loading
        super('record', id, '0', nil, 'record')
        self[:id] ||= self[:time].to_s # Session ID
        update(port: 55_555, cid: nil, label: nil, pid: '0')
        update(mode: 'test', status: 'ready', result: 'busy')
        # :status = ready,run,query,end
        # :result = busy, complete, (error message)
        update(total_steps: 0, total_time: 0, start: 0)
        self[:steps] = Arrayx.new
        @result = nil
        @finish_procs = []
      end

      def to_v
        msg = title_s
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

      def title_s
        date = Time.at(self[:id][0, 10].to_i)
        Msg.colorize(self[:mode].upcase, 3) +
          format(":%s (%s) [%s]\n", self[:label], self[:cid], date)
      end

      def jread(str = nil)
        res = super
        res[:steps].map! do |i|
          Step.new(res[:start]).update(i)
        end
        res
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('< record_file', options: 'r') do |_opt, _args|
        raise(InvalidARGS, 'No Input File') if STDIN.tty?
        puts Record.new.jmerge
      end
    end
  end
end
