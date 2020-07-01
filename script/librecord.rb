#!/usr/bin/env ruby
require 'libvarx'
require 'libstep'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Record
    class Record < Varx
      attr_accessor :result
      attr_reader :finish_procs
      # Level [0] Step, [1] Record & Item, [2] Group, [3] Domain, [4] Command
      def initialize(id = nil) # Session ID for Loading
        super('record', id)
        _attr_set('0', nil, 'record')
        @id ||= self[:id] = self[:time].to_s
        type?(@id, String)
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

      def refresh
        delete(:option)
        self
      end

      def jverify(hash = {})
        refresh
        res = super
        (res[:steps] || []).map! do |i|
          Step.new(res[:start]).update(i)
        end
        res
      end
    end

    if $PROGRAM_NAME == __FILE__
      Opt::Get.new('[record_id] | < record_file', options: 'rh') do |opt, args|
        puts Record.new(args.shift).cmode(opt.host)
      end
    end
  end
end
