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
        update(ver: 0, cid: nil, label: nil, pid: 0, status: 'ready')
        update(result: 'busy', total_steps: 0, total_time: 0, start: 0)
        self[:steps] = Arrayx.new
      end

      def to_v
        msg = title
        self[:steps].each do |i|
          msg << i.title + i.result
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
      end

      def load(str = nil)
        super
        _ext_steps
      end

      private

      def _ext_steps
        self[:steps].each do |i|
          i.extend(PrtShare).ext_prt(self[:start])
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[cid(latest)] (< file)', 'r') do |_opt, args|
        if STDIN.tty?
          fail(InvalidARGS, 'No input') if args.size < 1
          cid = '"cid":"' + args.shift + '"'
          ary = Dir.glob(Msg.vardir('json') + 'record_1*').sort.reverse
          fname = ary.find do |fn|
            fn if File.readlines(fn).grep(/#{cid}/)
          end
          /[0-9]{13}/ =~ fname
          rec = $& ? Record.new($&).ext_file : Record.new
        else
          rec = Record.new.read
        end
        puts rec
      end
    end
  end
end
