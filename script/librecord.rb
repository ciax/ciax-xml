#!/usr/bin/ruby
require 'libstatus'
require 'libstep'

module CIAX
  module Mcr
    class Record < Datax
      # Level [0] Step, [1] Record & Item, [2] Group, [3] Domain, [4] Command
      def initialize(id = nil) # Session ID for Loading
        super('record', [], 'steps')
        self['id'] = id || self['time'].to_s # Session ID
      end

      # cfg will come from Entity, which should have [:cid],['label'],@layers[:wat]
      # cfg doesn't change
      def start(cfg)
        @cfg = type?(cfg, Config)
        self['start'] = now_msec.to_s
        self['ver'] = @cfg['ver'] || '0' # Version
        self['cid'] = @cfg[:cid] # Command ID (cmd:par)
        self['label'] = @cfg['label'] # Label for CID
        self
      end

      def add_step(e1, depth)
        step = Step.new(e1, @cfg[:dev_list])
        step.post_upd_procs << proc{
          verbose { 'Propagate Step#upd -> Record#upd' }
          post_upd
        }
        step['time'] = Msg.elps_sec(self['time'])
        step['depth'] = depth
        @data << step
        step
      ensure
        post_upd
      end

      def finish
        self['total_time'] = Msg.elps_sec(self['time'])
        self['result']
      ensure
        post_upd
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
        msg
      end
    end

    if __FILE__ == $0
      OPT.parse('r')
      OPT.usage '(-r) < record_file' if STDIN.tty?
      puts Record.new.read
    end
  end
end
